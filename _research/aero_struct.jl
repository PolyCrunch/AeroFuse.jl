##
using Revise
using AeroMDAO
using LinearAlgebra
using StaticArrays
using DataFrames
using NLsolve
using Einsum

include("../src/Aerostructural/aerostruct.jl")

# Case
#==========================================================================================#

## Aerodynamic variables

# Define wing
wing = WingSection(root_foil  = naca4((2,4,1,2)),
                   span       = 2.6,
                   dihedral   = 0.0,
                   sweep_LE   = 0.0,
                   taper      = 1.0,
                   root_chord = 0.314,
                   root_twist = 0.0,
                   tip_twist  = 0.0)
wing_mac    = mean_aerodynamic_center(wing)
wing_plan   = plot_wing(wing)
wing_name   = "Wing"
print_info(wing)

# Mesh
span_num        = 10
chord_num       = 4
panels, normies = panel_wing(wing, span_num, chord_num);
aircraft        = Dict(wing_name => (panels, normies));

# Set up aerodynamic state
aero_state = VLMState(0., 0., 0., [0.0, 0.0, 0.0], 
                      rho_ref   = 1.225,
                      r_ref     = [ wing_mac[1], 0., 0. ],
                      area_ref  = projected_area(wing), 
                      chord_ref = mean_aerodynamic_chord(wing), 
                      span_ref  = span(wing));

# Test case - Fixed speed
aero_state.speed   = 25.
aero_state.alpha   = deg2rad(1.)
aero_state.rho_ref = 0.98

# Build system with initial guess from aerodynamic-only analysis
aero_system = solve_case(aircraft, aero_state)
aero_surfs  = surfaces(aero_system)
print_coefficients(aero_surfs[1], aero_state);

horses     = horseshoes(aero_system)
Γ_0        = circulations(aero_system)
# normies    = normals(aero_system)

## Aerodynamic forces and center locations
vlm_forces = surface_forces(aero_surfs[1]) 
horsies    = horseshoes(aero_surfs[1])
vlm_acs    = bound_leg_center.(horsies)

## Mesh setup
vlm_mesh   = chord_coordinates(wing, [span_num], chord_num, spacings = ["sine"])

## Weight variables (FOR FUTURE USE)

# W   = force(ff_t[3], q, S)
# W_y = fill(W / length(CFs) + 1, length(CFs) + 1)
# W   = (collect ∘ Iterators.flatten ∘ zip)(W_y, zeros(length(My)))
# F_W = [ zeros(length(py)); W; zeros(length(px)) ]
weight      = 15 * 9.81
load_factor = 1.0;

## Structural variables

# Beam properties
E     = 85e6  # Elastic modulus, N/m²
G     = 25e6  # Shear modulus, N/m²
σ_max = 350e6 # Yield stress with factor of safety 2.5, N/m²
ρ     = 1.6e3 # Density, kg/m³
ν     = 0.3   # Poisson ratio (UNUSED FOR NOW)
R     = 1e-2  # Outer radius, m
t     = 8e-3  # Thickness, m

# FEM mesh
fem_w    = 0.35
fem_mesh = make_beam_mesh(vlm_mesh, fem_w)
Ls       = norm.(diff(fem_mesh)) # Beam lengths, m 
aluminum = Material(E, G, σ_max, ρ)
tubes    = Tube.(Ref(aluminum), Ls, R, t)

# Stiffness matrix, loads and constraints
D         = build_big_stiffy(aluminum, tubes, fem_mesh)
fem_loads = compute_loads(vlm_acs, vlm_forces, fem_mesh)
cons      = [span_num]

## Solve system
dx        = solve_cantilever_beam(D, fem_loads, cons)
Δx        = [ zeros(6); dx[:] ]

## Aerostructural residual
#==========================================================================================#

solve_aerostructural_residual!(R, x) = solve_coupled_residual!(R, x, aero_system, aero_state, vlm_mesh, fem_mesh, weight, load_factor)

x0   = [ Γ_0; Δx[:]; aero_state.alpha ]
res_aerostruct = nlsolve(solve_aerostructural_residual!, x0,
                         method     = :newton,
                         show_trace = true,
                        #  extended_trace = true,
                        #  autodiff   = :forward,
                        )

## Check numbers
lift     = total_force(values(aero_surfs))[3]
load_fac = lift / weight

println("Load factor: $load_fac")
println("Weight: $weight N")
println("Lift: $lift N")
println("Speed: $(aero_state.speed) m/s")
println("Angle of attack: $(rad2deg(aero_state.alpha))ᵒ")


x_opt = res_aerostruct.zero 

## Compute displacements
dx         = @views reshape(x_opt[length(Γ_0)+7:end-1], 6, length(fem_mesh))
dxs        = @views SVector.(dx[1,:], dx[2,:], dx[3,:])
θx, θy, θz = @views dx[4,:], dx[5,:], dx[6,:]
Ts         = rotation_matrix.(θx, θy, θz)

# Perturb VLM mesh and normals
new_vlm_mesh   = transfer_displacements(dxs, Ts, vlm_mesh, fem_mesh)
new_panels = make_panels(new_vlm_mesh)

# New beams
new_fem_mesh = make_beam_mesh(new_vlm_mesh, fem_w)

## Aerodynamic forces and center locations
vlm_forces = surface_forces(aero_surfs[1]) 
horsies    = horseshoes(aero_surfs[1])
vlm_acs    = bound_leg_center.(horsies)
fem_loads  = compute_loads(vlm_acs, vlm_forces, fem_mesh)

## Generate DataFrames
df_Fs = DataFrame(permutedims(fem_loads), :auto)
rename!(df_Fs, [:Fx, :Fy, :Fz, :Mx, :My, :Mz])

df_xs = DataFrame(permutedims(dx), :auto)
rename!(df_xs, [:dx, :dy, :dz, :θx, :θy, :θz])

## Plotting
#==========================================================================================#

using Plots
pyplot(dpi = 300)

# Beam circles
n_pts          = 20
circle3D(r, n) = [ (r*cos(θ), 0, r*sin(θ)) for θ in 0:2π/n:2π ];
circ           = circle3D(R * 1e-4, n_pts) 

draw_tube(p1, p2, circ) = [ [ circ_pt .+ p1, circ_pt .+ p2 ] for circ_pt in circ ]

beam_pts     = zip(tupvector(fem_mesh[1:end-1]), tupvector(fem_mesh[2:end]))
circ_pts     = [ draw_tube(pt[1], pt[2], circ) for pt in beam_pts ]

new_beam_pts = zip(tupvector(new_fem_mesh[1:end-1]), tupvector(new_fem_mesh[2:end]))
new_circ_pts = [ draw_tube(pt[1], pt[2], circ) for pt in new_beam_pts ]

# Beam loads
fem_plot   = reduce(hcat, fem_mesh)
loads_plot = fem_loads

# Aerodynamic centers and forces
panel_plot = plot_panels(panels[:])
ac_plot    = reduce(hcat, vlm_acs)
force_plot = reduce(hcat, vlm_forces)

# Displacements
new_vlm_mesh_plot = reduce(hcat, new_vlm_mesh)
new_panel_plot = plot_panels(make_panels(new_vlm_mesh)[:])

# Plot
b = aero_state.span_ref
plot(camera = (45, 45), 
     xlim = (-b/2, b/2),
    #  ylim = (-b/2, b/2), 
     zlim = (0, b/2)
    )

# Panels
[ plot!(pans, color = :black, label = ifelse(i == 1, "Panels", :none)) for (i, pans) in enumerate(panel_plot) ]
[ plot!(pans, color = :brown, label = ifelse(i == 1, "Deflection", :none)) for (i, pans) in enumerate(new_panel_plot) ]

# Beams
[ plot!(reduce(vcat, pt), color = :green, label = ifelse(i == 1, "Beams", :none)) for (i, pt) in enumerate(circ_pts) ]
[ plot!(reduce(vcat, pt), color = :purple, label = ifelse(i == 1, "Deflected Beams", :none)) for (i, pt) in enumerate(new_circ_pts) ]

# Forces
# quiver!(fem_plot[1,:], fem_plot[2,:], fem_plot[3,:],
#         quiver=(loads_plot[1,:], loads_plot[2,:], loads_plot[3,:] ) .* 0.1,
#         label = "Beam Forces")
# quiver!(ac_plot[1,:], ac_plot[2,:], ac_plot[3,:],
#         quiver=(force_plot[1,:], force_plot[2,:], force_plot[3,:]) .* 0.1,
#         label = "Panel Forces")
# scatter!(ac_plot[1,:], ac_plot[2,:], ac_plot[3,:], label = "Aerodynamic Centers")

# Planform
plot!(wing_plan, color = :blue, label = "Planform")