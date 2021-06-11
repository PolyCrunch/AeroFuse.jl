## Wing analysis case
using Revise
using AeroMDAO

## Wing section setup
wing_foils = Foil.(fill(naca4((0,0,1,2)), 3))
wing_right = HalfWing(foils     = wing_foils,
                      chords    = [1.0, 0.6, 0.2],
                      twists    = [0.0, 0.0, 0.0],
                      spans     = [5.0, 0.5],
                      dihedrals = [5., 5.],
                      sweep_LEs = [5., 5.]);
wing = Wing(wing_right, wing_right)
wing_mac = mean_aerodynamic_center(wing)
S, b, c = projected_area(wing), span(wing), mean_aerodynamic_chord(wing);
print_info(wing, "Wing")

## Assembly
ρ       = 1.225
x_w     = wing_mac[1]
ref     = [ x_w; 0.; 0. ]
V, α, β = 1.0, 5.0, 5.0
Ω       = [0.0, 0.0, 0.0]
fs      = Freestream(V, α, β, Ω)

## Evaluate case
@time nf_coeffs, ff_coeffs, CFs, CMs, horseshoe_panels, normals, horseshoes, Γs = 
solve_case(wing, fs; 
           rho_ref   = ρ, 
           r_ref     = ref,
           area_ref  = S,
           span_ref  = b,
           chord_ref = c,
           span_num  = 12, 
           chord_num = 20,
           viscous   = true, # Only appropriate for α = β = 0, but works for other angles anyway
           x_tr      = [0.3, 0.3]);

print_coefficients(nf_coeffs, ff_coeffs, "Wing")

## Evaluate case with stability derivatives
@time nf, ff, dvs = 
solve_stability_case(wing, fs; 
                     rho_ref    = ρ, 
                     r_ref      = ref, 
                     area_ref   = S, 
                     span_ref   = b, 
                     chord_ref  = c, 
                     span_num   = [25, 4], 
                     chord_num  = 6, 
                     name       = "My Wing",
                     viscous    = true,
                     x_tr       = [0.3, 0.3],
                     print      = false);

#
print_coefficients(nf, ff, "Wing")
print_derivatives(dvs, "Wing")

## Plotting
using StaticArrays
using Plots
gr(size = (600, 400), dpi = 300)

## Coordinates
horseshoe_coords = plot_panels(horseshoe_panels[:])
wing_coords      = plot_wing(wing);

wind_CFs    = body_to_wind_axes.(CFs, α, β) # Transforming body forces to wind axes, needs further checkings
panel_areas = @. panel_area(horseshoe_panels)
CDis        = @. getindex(wind_CFs, 1)
CYs	       = @. getindex(wind_CFs, 2)
CLs         = @. getindex(wind_CFs, 3)
CL_loadings = 2sum(Γs, dims = 1)[:] / (V * c)

colpoints = horseshoe_point.(horseshoe_panels)
xs        = getindex.(colpoints, 1);
ys        = getindex.(colpoints, 2);
zs        = getindex.(colpoints, 3);

# Exaggerated CZ distribution for plot
cz_pts    = tupvector(SVector.(xs[:], ys[:], zs[:] .+ CLs[:]));

## Streamlines

# Chordwise distribution
# num_points = 50
# max_z = 0.1
# y = span(wing) / 2 - 0.05
# seed = SVector.(fill(-0.1, num_points), fill(y, num_points), range(-max_z, stop = max_z, length = num_points))

# Spanwise distribution
span_points = 20
init        = trailing_chopper(ifelse(β == 0 && Ω == zeros(3), wing.right, wing), span_points) 
dx, dy, dz  = 0, 0, 1e-3
seed        = [ init .+ Ref([dx, dy, dz])  ; 
                init .+ Ref([dx, dy, -dz]) ];

distance = 5
num_stream_points = 100
streams = plot_streams(fs, seed, horseshoes, Γs, distance, num_stream_points);

## Display
z_limit = 5
plot(xaxis = "x", yaxis = "y", zaxis = "z",
     aspect_ratio = 1, 
     camera = (30, 60),
     zlim = (-0.1, z_limit),
     size = (800, 600))
plot!.(horseshoe_coords, color = :black, label = :none)
scatter!(tupvector(colpoints)[:], marker = 1, color = :black, label = :none)
plot!.(streams, color = :green, label = :none)
plot!()

## Spanwise forces
span_areas = sum(panel_areas, dims = 1)[:]
span_CDis = sum(CDis, dims = 1)[:] * S ./ span_areas
span_CYs  = sum(CYs, dims = 1)[:] * S ./ span_areas
span_CLs  = sum(CLs, dims = 1)[:] * S ./ span_areas

plot_CD = plot(ys[1,:], span_CDis, label = :none, ylabel = "CDi")
plot_CY = plot(ys[1,:], span_CYs, label = :none, ylabel = "CY")
plot_CL = begin 
            plot(ys[1,:], span_CLs, label = :none, xlabel = "y", ylabel = "CL")
            plot!(ys[1,:], CL_loadings, label = "Normalized", xlabel = "y")
          end
plot(plot_CD, plot_CY, plot_CL, layout = (3,1))

## Lift distribution
plot(xaxis = "x", yaxis = "y", zaxis = "z",
     aspect_ratio = 1,
     camera = (25, 30),
     zlim = (-0.1, z_limit)
    )
plot!(wing_coords, label = "Wing Planform")
scatter!(cz_pts, zcolor = CLs[:], marker = 2, label = "CL (Exaggerated)")
plot!(size = (800, 600), colorbar = :none)