### A Pluto.jl notebook ###
# v0.19.46

#> [frontmatter]
#> title = "Overall Aircraft Design Demo"
#> layout = "layout.jlhtml"
#> tags = ["aerofuse"]
#> description = ""

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ d3da7be0-aef5-4ea1-9655-00714ac25557
#using AeroFuse
using Pkg;
#using https://github.com/PolyCrunch/AeroFuse.jl

# ╔═╡ f95c7d8c-5196-4e6b-88a0-bf9f0db626cb
Pkg.develop(url="https://github.com/PolyCrunch/AeroFuse.jl")

# ╔═╡ a3fcad3d-5d8f-4290-88d5-30764c2c689e
using AeroFuse

# ╔═╡ ef767260-419e-4029-b7cd-c202790668a5
using Plots

# ╔═╡ 6f7b9b78-02af-43f1-8f71-8da6f8ac9aea
using DataFrames

# ╔═╡ 5693bae3-e676-497c-baef-c84472270cef
begin
	using PlutoUI
	TableOfContents()
end

# ╔═╡ 50f026a9-84f2-4152-a1f6-b3c55c84e8ea
md"""# AeroFuse: Aircraft Design Demo

**Author**: [Arjit SETH](https://godot-bloggy.xyz), Research Assistant, MAE, HKUST.

"""

# ╔═╡ edd3a37f-2ed3-4f9d-9275-58d6859a9396
Pkg.status("AeroFuse")

# ╔═╡ 47df8df1-3923-44a1-a19e-845246737b1e
gr(
	size = (900, 700),  # INCREASE THE SIZE FOR THE PLOTS HERE.
	palette = :tab20    # Color scheme for the lines and markers in plots
)

# ╔═╡ f5aadd23-1d7b-4c3b-be6e-111e431357e1
md"## Aircraft Geometry"

# ╔═╡ f6a0b7bc-4722-49d9-98c8-37822febca88
md"""

Here, we'll refer to a passenger jet (based on a Boeing 777), but you can modify it to your design specifications.

![](https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/dc763bf2-302c-46be-8a52-4cb7c11598e5/d74vi3c-372cf93b-f4ad-4046-85e3-49f667d3c55a.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcL2RjNzYzYmYyLTMwMmMtNDZiZS04YTUyLTRjYjdjMTE1OThlNVwvZDc0dmkzYy0zNzJjZjkzYi1mNGFkLTQwNDYtODVlMy00OWY2NjdkM2M1NWEucG5nIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.bS5c5rkhqB2yoaOmIeRut7TgVsqgnPIfMOBSgYOO-TI)

"""

# ╔═╡ 343af23b-4c4d-422b-81d2-4bc4e5407dac
md"""### Fuselage"""

# ╔═╡ 2ef0a234-499b-4e23-b7d7-c3fcadd14752
# Fuselage definition
fuse = HyperEllipseFuselage(
    radius = 3.04,          # Radius, m
    length = 63.5,          # Length, m
    x_a    = 0.15,          # Start of cabin, ratio of length
    x_b    = 0.7,           # End of cabin, ratio of length
    c_nose = 1.6,            # Curvature of nose
    c_rear = 1.3,           # Curvature of rear
    d_nose = -0.5,          # "Droop" or "rise" of nose, m
    d_rear = 1.0,           # "Droop" or "rise" of rear, m
    position = [0.,0.,0.]   # Set nose at origin, m
)

# ╔═╡ 26d5c124-3da7-4a5a-b06e-38627b2dd8ac
begin
	# Compute geometric properties
	ts = 0:0.1:1                # Distribution of sections for nose, cabin and rear
	S_f = wetted_area(fuse, ts) # Surface area, m²
	V_f = volume(fuse, ts)      # Volume, m³
end

# ╔═╡ e8a84941-3ab0-461c-9ab8-cb0b5515989f
md"You can access the position by the `.affine.translation` attribute."

# ╔═╡ 9860d2fa-b497-4377-afe7-367b4a00e50d
fuse.affine.translation # Coordinates of nose

# ╔═╡ ef839605-88c5-4469-ae55-47961eb5417b
# Get coordinates of rear end
fuse_end = fuse.affine.translation + [ fuse.length, 0., 0. ]

# ╔═╡ 635f6baa-e360-45b2-87de-fedf1ec52b4a
fuse_end.x 	# Access x-coordinate

# ╔═╡ 65661116-c2a5-4684-aa1d-8514e6310025
md"""

!!! warning
	You may have to change the fuselage dimensions when estimating weight, balance and stability according to the design requirements!
"""

# ╔═╡ 74330174-edfd-4e13-8bc1-f8c80c163be0
md"### Wing"

# ╔═╡ 1bf4c10a-1801-41be-b06f-677f44a156a7
begin
	# AIRFOIL PROFILES
	foil_w_r = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=b737a-il")) # Root
	foil_w_m = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=b737b-il")) # Midspan
	foil_w_t = read_foil(download("http://airfoiltools.com/airfoil/seligdatfile?airfoil=b737c-il")) # Tip
end

# ╔═╡ 7758fb66-991d-49f7-b8f8-a3549fb0e340
# Wing
wing = Wing(
    foils       = [foil_w_r, foil_w_m, foil_w_t], # Airfoils (root to tip)
    chords      = [14.0, 9.73, 1.43561],        # Chord lengths
    spans       = [14.0, 46.9] / 2,             # Span lengths
    dihedrals   = fill(6, 2),                   # Dihedral angles (deg)
    sweeps      = fill(35.6, 2),                # Sweep angles (deg)
    w_sweep     = 0.,                           # Leading-edge sweep
    symmetry    = true,                         # Symmetry

	# Orientation
    angle       = 3,       # Incidence angle (deg)
    axis        = [0, 1, 0], # Axis of rotation, x-axis
    position    = [0.35fuse.length, 0., -2.5]
)

# ╔═╡ d61de21f-5d28-4bd9-8b41-0d0be92f9e76
b_w = span(wing) # Span length, m

# ╔═╡ d54578a4-d0e6-4b18-bc13-477467b2a058
S_w = projected_area(wing) # Area, m

# ╔═╡ 79dd19b4-10cc-44a8-ba62-4a7ef1ceb752
c_w = mean_aerodynamic_chord(wing) # Mean aerodynamic chord, m

# ╔═╡ d154be95-8350-4c38-8b02-10595d9764cd
mac_w = mean_aerodynamic_center(wing, 0.25) # Mean aerodynamic center (25%), m

# ╔═╡ 958906a9-75c3-4ead-aafe-2596623b89c0
mac40_wing = mean_aerodynamic_center(wing, 0.4) # Mean aerodynamic center (40%), m

# ╔═╡ 35a249a3-7272-435a-a5d3-5e8ba8a655ca
md"""

!!! warning
	You may have to change the wing size and locations when estimating weight, balance and stability!
"""

# ╔═╡ bec4f70a-7ff0-4c0e-8759-758a95831e46
md"### Engines"

# ╔═╡ cd2e5706-bfc9-4fca-90bd-70460198c9ee
md"We can place the engines based on the wing and fuselage geometry."

# ╔═╡ 187d4c9e-e366-4395-9b3e-b0cefbf9ce5d
wing_coo = coordinates(wing) # Get leading and trailing edge coordinates. First row is leading edge, second row is trailing edge.

# ╔═╡ 82731c8d-7819-42d3-afd1-eabfbad8303b
wing_coo[1,:] # Get leading edge coordinates

# ╔═╡ da2ef327-9171-4daf-98e2-ed679d6f84e2
begin
	# Example:
	eng_L = wing_coo[1,2] - [1, 0., 0.] # Left engine, at mid-section leading edge
	eng_R = wing_coo[1,4] - [1, 0., 0.] # Right engine, at mid-section leading edge
end

# ╔═╡ 79a60ed4-5281-4261-90fb-5f2bfc928758
md"""

!!! warning
	You may have to change the engine locations when estimating weight, balance and stability!
"""

# ╔═╡ 3dd1f51b-26e2-44f1-b754-fb58612e7d7c
md"### Stabilizers"

# ╔═╡ 63a82ccb-21e4-4edc-81df-cd9f84953372
md"#### Horizontal Tail"

# ╔═╡ 647698ec-1f80-4ddd-ae98-f40a05ea75c6
con_foil = control_surface(naca4(0,0,1,2), hinge = 0.75, angle = -10.)

# ╔═╡ fbeb3c61-6c88-4aa5-9925-3510a00e366e
htail = WingSection(
    area        = 101,  			# Area (m²). HOW DO YOU DETERMINE THIS?
    aspect      = 4.2,  			# Aspect ratio
    taper       = 0.4,  			# Taper ratio
    dihedral    = 7.,   			# Dihedral angle (deg)
    sweep       = 35.,  			# Sweep angle (deg)
    w_sweep     = 0.,   			# Leading-edge sweep
    root_foil   = con_foil, 	# Root airfoil
	tip_foil    = con_foil, 	# Tip airfoil
    symmetry    = true,

    # Orientation
    angle       = 5,  # Incidence angle (deg). HOW DO YOU DETERMINE THIS?
    axis        = [0., 1., 0.], # Axis of rotation, y-axis
    position    = fuse_end - [ 10., 0., 0.], # HOW DO YOU DETERMINE THIS?
)

# ╔═╡ 7432a455-aff6-4a22-8576-9249f67b5dd7
b_h = span(htail)

# ╔═╡ 25fb28f6-4571-4b87-8a7d-9465eae537de
S_h = projected_area(htail)

# ╔═╡ c1ed6eb3-a0c7-484e-a511-2e13df3a2040
c_h = mean_aerodynamic_chord(htail)

# ╔═╡ 185f315c-ccc9-4c9c-be91-f30c8046b27a
mac_h = mean_aerodynamic_center(htail)

# ╔═╡ 8ab5fc32-41f1-4492-bc35-7d0cb5864162
V_h = S_h / S_w * (mac_h.x - mac_w.x) / c_w

# ╔═╡ 79978d9e-c28a-4787-9d6a-ac753331111e
md"#### Vertical Tail"

# ╔═╡ 72c1cb62-58da-40c8-a5ff-5f9325360fe8
vtail = WingSection(
    area        = 56.1, 			# Area (m²). # HOW DO YOU DETERMINE THIS?
    aspect      = 1.5,  			# Aspect ratio
    taper       = 0.4,  			# Taper ratio
    sweep       = 44.4, 			# Sweep angle (deg)
    w_sweep     = 0.,   			# Leading-edge sweep
    root_foil   = naca4(0,0,0,9), 	# Root airfoil
	tip_foil    = naca4(0,0,0,9), 	# Tip airfoil

    # Orientation
    angle       = 90.,       # To make it vertical
    axis        = [1, 0, 0], # Axis of rotation, x-axis
    position    = htail.affine.translation - [2.,0.,-1.] # HOW DO YOU DETERMINE THIS?
) # Not a symmetric surface

# ╔═╡ 02dcefce-3b27-441f-a76b-9dba2c7b2b72
b_v = span(vtail)

# ╔═╡ 659c3d72-85e2-4f39-aa49-cbc83066c345
S_v = projected_area(vtail)

# ╔═╡ a259c6c0-939e-4af0-a1d4-11d088b4c7db
c_v = mean_aerodynamic_chord(vtail)

# ╔═╡ 8effef36-3f6c-4179-877d-3f0e03863a22
mac_v = mean_aerodynamic_center(vtail)

# ╔═╡ edd73ae8-6bf2-4585-9275-166e3ee7a017
V_v = S_v / S_w * (mac_v.x - mac_w.x) / b_w

# ╔═╡ f2587d9c-8028-46f7-9610-869d9eb15c73
md"""

!!! warning
	You may have to change the tail size and locations when estimating weight, balance and stability!

"""

# ╔═╡ 117d30e6-1252-4198-b348-6a1e5e798070
md"### Visualization"

# ╔═╡ 5342b18a-7fe2-46b4-a53f-91399797b971
md"""## Aerodynamic Analysis

!!! info
	Refer to the **Aerodynamic Analysis** tutorial in the AeroFuse documentation to understand this process: [https://hkust-octad-lab.github.io/AeroFuse.jl/stable/tutorials-aircraft/](https://hkust-octad-lab.github.io/AeroFuse.jl/stable/tutorials-aircraft/)

"""

# ╔═╡ a26930b4-f8aa-41bf-8375-fac549980ca3
md"### Meshing"

# ╔═╡ 21b17672-2800-4876-a83a-b04f5b94cf76
wing_mesh = WingMesh(wing, 
	[8,16], # Number of spanwise panels
	10,     # Number of chordwise panels
    span_spacing = Uniform() # Spacing: Uniform() or Cosine()
)

# ╔═╡ bfdc099a-bdac-4b8f-8ef8-a1c2003c6d43
htail_mesh = WingMesh(htail, [10], 8)

# ╔═╡ b61af5cc-a240-4670-93d0-aeb01208d01d
vtail_mesh = WingMesh(vtail, [8], 6)

# ╔═╡ 696e35a8-1ece-4a7b-a160-ec6d2a3134c0
md"### Vortex Lattice Method"

# ╔═╡ cb819012-a6cd-462e-bee1-c118ba8f3caf
md"The vortex lattice method (VLM) provides decent estimations of the aerodynamic lift and stability in the preliminary design stages."

# ╔═╡ b672ad66-01a4-48b3-a169-02d97d4b9baa
# Define aircraft
ac = ComponentVector(# ASSEMBLE MESHES INTO AIRCRAFT
	wing  = make_horseshoes(wing_mesh),   # Wing
	htail = make_horseshoes(htail_mesh),  # Horizontal Tail
	vtail = make_horseshoes(vtail_mesh)   # Vertical Tail
)

# ╔═╡ 5b611e79-5689-4a33-929e-5c77dee7f958
# Define freestream conditions
fs = Freestream(
	alpha = 0.0, # Angle of attack, deg. HOW DO YOU CHOOSE THIS?
	beta = 0.0,  # Angle of sideslip, deg.
) 

# ╔═╡ c429a2d2-69b9-437d-a138-efee4b118016
M = 0.84 # Operating Mach number.

# ╔═╡ 36b197b3-1971-4c73-96ec-7370002ade1e
# Define reference values
refs = References(
	density = 0.35, # Density at cruise altitude.
					# HOW DO YOU CALCULATE THIS BASED ON THE ALTITUDE?
	
	speed = M * 330., # HOW DO YOU DETERMINE THE SPEED?

	# Set reference quantities to wing dimensions.
	area = projected_area(wing), 			# Area, m²
	chord = mean_aerodynamic_chord(wing),   # Chord, m
	span = span(wing), 						# Span, m
	
	location = fuse.affine.translation, # From the nose as reference (origin)
)

# ╔═╡ e358c252-4592-4ae6-bd90-bf237dc3ee1d
# Run vortex lattice analysis
sys = solve_case(ac, fs, refs,
		name = "Boing",
		compressible = true,
	)

# ╔═╡ dfd216a0-817c-43b2-bb0a-e2f5bb28650d
md"""### Aerodynamic Coefficients

Two methods are provided for obtaining the force and moment coefficients from the VLM analysis.

"""

# ╔═╡ c736beb7-6714-4931-9e35-e452a9647682
md"#### Nearfield"

# ╔═╡ 9b09f4bb-f7a9-460c-aa99-18a78f60ed4c
nfs = nearfield(sys) # Nearfield coefficients (force and moment coefficients)

# ╔═╡ e4cdffdb-33ca-4280-b8cf-965642bdc3af
nfs.CX # Induced drag coefficient (nearfield)

# ╔═╡ aa92101c-7cd1-4c80-8296-15fa126bac25
nfs.CZ # Lift coefficient (nearfield)

# ╔═╡ f9f88f4c-9cf7-466b-b70a-5331eb2cbb5c
nfs.Cm # Pitching moment coefficient

# ╔═╡ f0ba714d-2710-4558-b078-24ae0faeb1e0
md"#### Farfield"

# ╔═╡ 0521760f-4ba0-4910-bf9d-8f345a5616a3
ffs = farfield(sys) # Farfield coefficients (no moment coefficients)

# ╔═╡ 0088977f-7cde-4c9b-9bce-c4977f62a3f7
ffs.CDi # Induced drag coefficient (farfield)

# ╔═╡ 84352c40-13f2-45c3-9244-d996a67777b8
ffs.CL # Lift coefficient (farfield)

# ╔═╡ 81b627fb-263f-44fb-8e4e-4a4fe075dbc0
md"""

!!! tip
	Use the farfield coefficients for the induced drag, as they are usually much more accurate than the nearfield coefficients.

"""

# ╔═╡ c60041fa-242f-4847-8ba1-e0bb12c0aeb4
ffs.CL / ffs.CDi # Lift-to-induced drag ratio

# ╔═╡ c0fcf470-4f20-4bbc-adad-dbf82492b1fb
print_coefficients(nfs, ffs)

# ╔═╡ 3be74cb9-4e2f-483a-ac57-0b80732218e0
md"""## Weight and Balance Estimation

The component weights of the aircraft are some of the largest contributors to the longitudinal stability characteristics.

![](https://raw.githubusercontent.com/HKUST-OCTAD-LAB/MECH3620Materials/main/pics/777200LRMoments.svg)

Recall the definition of the center of gravity (CG):
```math
\mathbf{r}_\text{cg} = \frac{\sum_i \mathbf{M}_i}{\sum_i W_i} = \frac{\sum_i W_i \ (\mathbf{r}_{\text{cg}})_i}{\sum_i W_i}, \quad \mathbf{r} = \begin{bmatrix}
  x \\ y \\ z
\end{bmatrix}
```

where $W_i$ represents the weight for each component and $(\mathbf r_{\text{cg}})_i$ is the position vector between the origin and the CG of the $i$th component. The product in the form $W_i(\mathbf r_{\text{cg}})_i$ is also referred to as the moment $\mathbf M_i$ induced by the $i$th component.

"""

# ╔═╡ c2f25eac-7453-420a-bcda-ad70a438358f
md"### Statistical Weight Estimation"

# ╔═╡ 08c88bf1-72f9-4e54-926f-b8f8fdbb8179
# WRITE STATISTICAL WEIGHT ESTIMATION FORMULAS AND COMPUTATIONS

# ╔═╡ 07971f8e-fd34-4292-a021-278b567ee3ef


# ╔═╡ 737189fe-e73d-4dbc-a172-da713925bd1d
md"#### Component Weight Build-up"

# ╔═╡ 521c7938-d392-4831-b62b-bd4221cff162
md"Based on the statistical weight estimation method and weight estimation of other components, you can determine most of the weights and assign them to variables."

# ╔═╡ ddfa28f9-de7c-4faa-a998-bdfa1a17a223
g = 9.81 # Gravitational acceleration, m/s²

# ╔═╡ 091fdf20-508c-48a1-aaa5-ad13722a540b
lb_ft2_to_kg_m2 = 4.88243 # Convert lb/ft² to kg/m²

# ╔═╡ 70d90871-53ab-402a-9a6d-1dd727e5c6d0
begin
	# Weights
	#====================================================#
	
	# THIS HAS BEEN DONE BASED ON PRELIMINARY ESTIMATION. 
	# YOU MUST REVISE IT BASED ON STATISTICAL WEIGHTS.

	TOGW 	= 347458 * g # Takeoff gross weight, N
	W_other = 0.17 * TOGW # All other components

	# Engine
	W_engine 	 = 8762 * g # GE90-110B1 engine weight (single), N
	W_engine_fac = 1.3 * W_engine # Scaling factor for engine weight

	# Lifting surfaces (HINT: REPLACE WITH STATISTICAL WEIGHTS)
	W_wing 	= S_w * 10 * lb_ft2_to_kg_m2 * g
	W_htail = S_h * 5.5 * lb_ft2_to_kg_m2 * g
	W_vtail = S_v * 5.5 * lb_ft2_to_kg_m2 * g
	W_fuse 	= S_f * 5.0 * lb_ft2_to_kg_m2 * g

	# Landing gear
	W_nLG = 0.043 * 0.15 * TOGW # Nose
	W_mLG = 0.043 * 0.85 * TOGW # Main landing gear

	# THERE ARE MORE COMPONENT WEIGHTS YOU NEED TO ACCOUNT FOR!!!
	# HINT: PASSENGERS??? LUGGAGE??? FUEL???
end

# ╔═╡ 5838b73b-a044-4f63-b3b8-88c5b96e0f83
md"### Component Locations"

# ╔═╡ 27e4439a-9f40-40a9-8603-e80161da8004
md"Now determine and modify the locations of each component sensibly."

# ╔═╡ 3c345c72-12cd-4573-a957-5bc5fe3caeb0
begin
	# Locations
	#====================================================#

	# THIS HAS BEEN DONE BASED ON PRELIMINARY ESTIMATION. 
	# YOU MUST REVISE IT FOR THE BALANCE AND STABILITY OF YOUR AIRCRAFT.
	
	r_w = mean_aerodynamic_center(wing, 0.4)   # Wing, 40% MAC
	r_h = mean_aerodynamic_center(htail, 0.4)  # HTail, 40% MAC
	r_v = mean_aerodynamic_center(vtail, 0.4)  # VTail, 40% MAC

	r_eng_L = wing_coo[1,2] - [1., 0., 0.]     # Engine, near wing LE
	r_eng_R = wing_coo[1,4] - [1., 0., 0.] 	   # Engine, near wing LE

	# Nose location 
	r_nose 	= fuse.affine.translation

	# Fuselage centroid (50% L_f)
	r_fuse 	= r_nose + [fuse.length / 2, 0., 0.]

	# All-other component centroid (40% L_f)
	r_other = r_nose + [0.4 * fuse.length, 0., 0.]

	# Nose landing gear centroid (15% L_f)
	r_nLG  	= r_nose + [0.15 * fuse.length, 0., -fuse.radius]

	# Main landing gear centroid (50% L_f)
	r_mLG 	= r_nose + [0.5 * fuse.length, 0., -fuse.radius]

	# THERE ARE MORE COMPONENT LOCATIONS YOU NEED TO ACCOUNT FOR!!!
end;

# ╔═╡ 14a79c53-1d0a-438e-8a9b-e7dafbef1322
md"### Center of Gravity Calculation"

# ╔═╡ 7a05752f-522c-4f5e-84fc-bd9624deb07e
md"Finally, assemble this information into a dictionary."

# ╔═╡ c197c2fd-cd78-4aa6-83c1-bb34d6579c80
# Component weight and location dictionary
W_pos = Dict(
	# "Component"   => (Weight, Location)
	"Engine L CG" 	=> (W_engine_fac, r_eng_L),
	"Engine R CG" 	=> (W_engine_fac, r_eng_R),
	"Wing CG"   	=> (W_wing, r_w), 
	"HTail CG"  	=> (W_htail, r_h), 
	"VTail CG"  	=> (W_vtail, r_v),
	"Fuse CG"   	=> (W_fuse, r_fuse),
	"All-Else CG" 	=> (W_other, r_other),
	"Nose LG CG" 	=> (W_nLG, r_nLG), 
	"Main LG CG" 	=> (W_mLG, r_mLG),
);

# ╔═╡ dc99a9c2-cb70-4498-b9ed-6295fff11884
keys(W_pos) # Get keys

# ╔═╡ a34e91e7-927e-4b0a-b72b-0813e098f000
values(W_pos) # Get values

# ╔═╡ 516a6341-aa4d-4811-aaa1-c65ed92b0357
 # Total weight evaluation using array comprehension, N
W_tot = sum(W_i for (W_i, r_i) in values(W_pos))

# ╔═╡ ff34f0e0-dc07-467a-88cb-6d287ba4463b
m_tot = W_tot / g 	# Total mass, kg

# ╔═╡ 774c9f2b-3e2f-4f74-bf22-28745063cfae
M_tot = sum(W_i * r_i for (W_i, r_i) in values(W_pos)) # Total moment, N-m

# ╔═╡ 38e5cf39-0766-400b-9312-e39b673faac6
md"""

!!! tip
	Check whether the sum of the weights matches the estimated total weight! It may not be exactly close because:

	1. You have used statistical estimations for many of the weights.
	2. You may not have accounted for all the relatively heavy components.

"""

# ╔═╡ f1b551ba-4f27-4bec-af09-7554c2e76045
# CG estimation, m
r_cg = M_tot / W_tot

# ╔═╡ 6e8dead0-6af0-4324-928d-e19b295c9b5b
x_cg = r_cg.x  # x-component

# ╔═╡ 140c3020-58b1-439b-9772-7b17b5915b40
md"""## Stability Analysis

!!! info
	Refer to the **Aerodynamic Stability Analysis** tutorial in the AeroFuse documentation to understand this process: [https://hkust-octad-lab.github.io/AeroFuse.jl/stable/tutorials-stability/](https://hkust-octad-lab.github.io/AeroFuse.jl/stable/tutorials-stability/)

"""

# ╔═╡ 10632c4e-7aa0-4f99-a9ff-39ccad2da377
md"""### Static Margin Estimation

In addition to the weights, the aerodynamic forces depicted are also major contributors to the stability of a conventional aircraft configuration.

![](https://raw.githubusercontent.com/HKUST-OCTAD-LAB/MECH3620Materials/main/pics/777200LR.svg)

**CAD Source:** [https://grabcad.com/library/boeing-777-200](https://grabcad.com/library/boeing-777-200)

This interrelationship between aerodynamics and weights on stability is expressed via the static margin.

```math
\text{Static Margin} = \frac{x_{np} - x_{cg}}{\bar c} 
```

We need to determine both of these locations: the center of gravity $x_{cg}$ and the neutral point $x_{np}$.
"""

# ╔═╡ 7867678b-5910-45a5-a8fd-59ace4d0dc7b
md"""

#### Neutral Point

The neutral point is:
```math
\frac{x_{np}}{\bar c} = -\left(\frac{\partial C_m}{\partial C_L} + \frac{\partial C_{m_f}}{\partial C_L}\right)
```
where $\partial C_m / \partial C_L$ is the moment-lift derivative excluding the fuselage contribution, and $\partial C_{m_f} / \partial C_L$ is the moment-lift derivative contributed by the fuselage.

"""

# ╔═╡ d02fe0a3-3523-4239-9b74-bf4e00b5e891
md"""First, we need to compute the aerodynamic stability derivatives:

```math
	\frac{\partial C_m}{\partial C_L} \approx \frac{C_{m_\alpha}}{C_{L_\alpha}}
```

"""

# ╔═╡ 8bcd6ea1-6711-4a0c-8f1c-bba12e843808
md"""
!!! info
	Enable the "Stability" checkbox in the plotting toggles to run the stability analysis.
"""

# ╔═╡ 37d4a03a-af97-4208-bfa1-6bb057f0f988
md""" ##### Fuselage Contribution
The moment-lift derivative of the fuselage is estimated via slender-body theory, which primarily depends on the volume of the fuselage. 

```math
\frac{\partial C_{m_f}}{\partial C_L} \approx \frac{2\mathcal V_f}{S_w \bar{c}C_{L_{\alpha_w}}} 
```

!!! tip 
	For estimating the volume without using [AeroFuse](https://github.com/GodotMisogi/AeroFuse.jl), you can initially approximate the fuselage as a square prism of length $L_f$ with maximum width $w_f$ (hence, $\mathcal V_f \approx w_f^2 L_f$) and introduce a form factor $K_f$ as a correction factor for the volume of the actual shape.
	```math
	\frac{\partial C_{m_f}}{\partial C_L} \approx \frac{K_f w_f^2 L_f}{S_w \bar{c}C_{L_{\alpha_w}}}
	```

	Your notes provide the empirical estimation of $K_f$.
"""

# ╔═╡ 97929c85-54c0-4976-95b6-d70364c68035
# FUSELAGE CM-CL DERIVATIVE
function fuse_Cm_CL(
		V_f, 	# Fuselage volume
		Sw, 	# Wing area 
		c_bar, 	# Mean aerodynamic chord
		CL_a_w 	# Lift curve slope
	)

	# Compute fuselage moment-lift derivative
	dCMf_dCL = 2 * V_f / (Sw * c_bar * CL_a_w)
	
	return dCMf_dCL
end

# ╔═╡ 072e8834-0a19-456a-b818-f436a847490b
# savefig(plt_vlm, "my_aircraft.png") # TO SAVE THE FIGURE

# ╔═╡ 0859eeeb-0dbf-4f39-a7a4-a5f828726b16
md"### Dynamic Stability"

# ╔═╡ 50751fc6-5704-4487-ba2f-9f37c21fbdfc
begin
	Ixx = span(wing) / √12 
	Iyy = chords(wing)[1] / √12 # Moment of inertia in x-z plane
	Izz = span(wing) / √12
end

# ╔═╡ 90ac16c3-37d4-42ae-a9ed-4572c49397dc
md"## Drag Estimation"

# ╔═╡ 27c05748-4570-4420-af08-15fd2a31a373
md"""

The total drag coefficient can be estimated by breaking down the drag contributions from the components:

```math
C_{D_0} = C_{D_{0,f}} + C_{D_{0,w}} + C_{D_{0,ht}} + C_{D_{0,vt}} + C_{D_{0,LG}} + C_{D_{0,N}} + C_{D_{0,S}} + C_{D_{0, HLD}} + \dots
```

"""

# ╔═╡ 05fd1ff1-b47d-4452-b0c0-b4a39a5b3d7e
md">AeroFuse provides the following `parasitic_drag_coefficient` function for estimating $C_{D_0}$ of the fuselage and wing components.
>
> This estimation can depend on whether the flow is laminar or turbulent. For high Reynolds numbers (i.e., $Re \geq 2\times 10^6$), the flow over all surfaces is usually fully turbulent."

# ╔═╡ 0c614e7c-27d9-45cf-90a2-699a02493a72
x_tr = 0.0 # Transition location to turbulent flow as ratio of chord length. 
# 0 = fully turbulent, 1 = fully laminar

# ╔═╡ de956d60-60b6-47cf-baa6-0cc65ac45877
CD0_fuse = parasitic_drag_coefficient(fuse, refs, x_tr) # Fuselage

# ╔═╡ bc4e06d3-1429-40f2-a2cc-d8c5c2e26872
CD0_wing = parasitic_drag_coefficient(wing_mesh, refs, x_tr) # Wing

# ╔═╡ e8cb0195-51d7-41e9-9e69-7c79e2f5d35f
CD0_htail = parasitic_drag_coefficient(htail_mesh, refs, x_tr) # HTail

# ╔═╡ 27a240c4-b201-4a49-b784-c454ff0f1575
CD0_vtail = parasitic_drag_coefficient(vtail_mesh, refs, x_tr) # VTail

# ╔═╡ 6717ffeb-626b-4ec0-a70d-3727dc8a4f0e
# Summed. YOU MUST ADD MORE BASED ON YOUR COMPONENTS (NACELLE, ETC.)
CD0 = CD0_fuse + CD0_wing + CD0_htail + CD0_vtail

# ╔═╡ 04f09813-3514-4e81-93ce-a3bf28610537
md"""We can sum the contributions from the components considered.

"""

# ╔═╡ e0614b11-3e67-4ce5-90ab-14e245449fcb
CD = CD0 + ffs.CDi # Evaluate total drag coefficient

# ╔═╡ 71a51430-9b8c-4f22-b41d-3a1532df159c
md"""
!!! danger "Alert!"
	You will have to determine the parasitic drag coefficients of the other terms (landing gear, high-lift devices, etc.) for your design on your own following the lecture notes and references.

	The summation also does not account for interference between various components, e.g. wing and fuselage junction. You may have to consider "correction factors" ($K_c$ in the notes) as multipliers following the references.
"""

# ╔═╡ e6439db0-d98a-4ae5-b706-c606f1caea4a
md"Based on this total drag coefficient, we can estimate the revised lift-to-drag ratio."

# ╔═╡ 46433eaf-fc72-4f4f-8dd7-811f4579b5f0
LD_visc = ffs.CL / CD # Evaluate lift-to-drag ratio

# ╔═╡ dee2f972-3b85-473b-adc1-5c3888c5daa0
md"# Plot Definition"

# ╔═╡ be8235a9-2633-41ac-a6d1-d2330d7146f9
begin
	φ_s 			= @bind φ Slider(0:1e-2:90, default = 15)
	ψ_s 			= @bind ψ Slider(0:1e-2:90, default = 30)
	aero_flag 		= @bind aero CheckBox(default = true)
	stab_flag 		= @bind stab CheckBox(default = true)
	weights_flag 	= @bind weights CheckBox(default = false)
	strm_flag 		= @bind streams CheckBox(default = false)
end;

# ╔═╡ 94e99222-efff-400d-b8b7-d378c53c8e9d
if stab
	# Evaluate the aerodynamic stability derivatives
	dvs = freestream_derivatives(
		sys, 					 # Input the aerodynamics (VortexLatticeSystem)
		# print_components = true, # Print derivatives for all components
		print = true, 		 # Print derivatives for only the aircraft
		farfield = true, 		 # Farfield derivatives (usually unnecessary)
	)
end

# ╔═╡ 6a292063-5989-4058-ab5c-898b1de0de73
if stab
	## Calculate longitudinal stability quantities
	#==============================================#
	
	ac_dvs = dvs.aircraft # Access the derivatives of the aircraft

	# Fuselage correction (COMPUTED USING FUSELAGE VOLUME AT THE BEGINNING)
	Cm_fuse_CL = fuse_Cm_CL(V_f, S_w, c_w, dvs.wing.CZ_al) # Fuselage Cm/CL
	
	x_np = -refs.chord * (ac_dvs.Cm_al / ac_dvs.CZ_al + Cm_fuse_CL) # Neutral point
	x_cp = -refs.chord * ac_dvs.Cm / ac_dvs.CZ # Center of pressure
	
	# Stability position vectors
	r_np = refs.location + [x_np, 0, 0]
	r_cp = refs.location + [x_cp, 0, 0]
	
	SM = (r_np - r_cg).x / refs.chord * 100 # Static margin (%)
end

# ╔═╡ 7a96bdd1-65b5-48cf-8ebc-36f0ba216965
lon_dvs = longitudinal_stability_derivatives(ac_dvs, refs.speed, W_tot, Iyy, dynamic_pressure(refs), refs.area, refs.chord)

# ╔═╡ 31cdcfd6-70b1-4bef-aecd-78c5d359540c
A_lon = longitudinal_stability_matrix(lon_dvs..., refs.speed, g)

# ╔═╡ 38185599-aa95-4716-9b2e-1af3b2548396
lat_dvs = lateral_stability_derivatives(ac_dvs, refs.speed, W_tot, Ixx, Izz, dynamic_pressure(refs), refs.area, refs.span)

# ╔═╡ da3ec2a7-109b-4f8e-bd5e-521e257b8693
A_lat = lateral_stability_matrix(lat_dvs..., refs.speed, g)

# ╔═╡ f020f165-37f9-45ed-8d21-1e8fc8e1591a
toggles = md"""
φ: $(φ_s)
ψ: $(ψ_s)

Panels: $(aero_flag)
Weights: $(weights_flag)
Stability: $(stab_flag)
Streamlines: $(strm_flag)
"""

# ╔═╡ 6075b162-6315-4bd8-bdff-007f3a278b66
toggles

# ╔═╡ 9ac640ed-b400-46f8-89bc-650a5d2801ff
toggles

# ╔═╡ a62696dc-171a-4978-8de9-0ab643987b41
toggles

# ╔═╡ 5d5a0da9-07e0-4be1-ba9c-a854299cd23f
toggles

# ╔═╡ 81f5072b-46e2-466f-8a76-b984d7f3b75e
toggles

# ╔═╡ 623332dc-d56a-478e-84ac-32fe9123c0c2
toggles

# ╔═╡ 06427107-e04a-44d0-9db1-76a9c7519895
toggles

# ╔═╡ 9e2fbbbb-5c69-4ed2-887f-4913db2d0153
begin
	# Plot meshes
	plt_vlm = plot(
	    # aspect_ratio = 1,
	    xaxis = "x", yaxis = "y", zaxis = "z",
	    zlim = (-0.5, 0.5) .* span(wing_mesh),
	    camera = (φ, ψ),
	)

	# Surfaces
	if aero
		plot!(fuse, label = "Fuselage", alpha = 0.6)
		plot!(wing_mesh, label = "Wing", mac = false)
		plot!(htail_mesh, label = "Horizontal Tail", mac = false)
		plot!(vtail_mesh, label = "Vertical Tail", mac = false)
	else
		plot!(fuse, alpha = 0.3, label = "Fuselage")
		plot!(wing, 0.4, label = "Wing MAC 40%") 			 
		plot!(htail, 0.4, label = "Horizontal Tail MAC 40%") 
		plot!(vtail, 0.4, label = "Vertical Tail MAC 40%")
	end

	# CG
	scatter!(Tuple(r_cg), label = "Center of Gravity (CG)")
	
	# Streamlines
	if streams
		plot!(sys, wing_mesh, 
			span = 4, # Number of points over each spanwise panel
			dist = 40., # Distance of streamlines
			num = 50, # Number of points along streamline
		)
	end

	# Weights
	if weights
		# Iterate over the dictionary
		[ scatter!(Tuple(pos), label = key) for (key, (W, pos)) in W_pos ]
	end

	# Stability
	if stab
		scatter!(Tuple(r_np), label = "Neutral Point (SM = $(round(SM; digits = 2))%)")
		# scatter!(Tuple(r_np_lat), label = "Lat. Neutral Point)")
		scatter!(Tuple(r_cp), label = "Center of Pressure")
	end
end

# ╔═╡ c44ee57c-0cba-4436-9557-b0c7eaf77c62
plt_vlm

# ╔═╡ 6085715c-9ab0-4fe8-b159-9a814bc572e8
plt_vlm

# ╔═╡ 07842e70-6c91-47cf-b480-28c690e4c0ab
plt_vlm

# ╔═╡ 2dedcfbb-7998-4767-a904-9930bf9bc796
plt_vlm

# ╔═╡ d71d2ebc-0406-4bad-99f4-2ec06d7ec759
plt_vlm

# ╔═╡ 61ec2044-e93e-4a70-8408-8cd48cc4f784
plt_vlm

# ╔═╡ f43d6358-5f1f-40e9-896f-37038ad04986
plt_vlm

# ╔═╡ Cell order:
# ╟─50f026a9-84f2-4152-a1f6-b3c55c84e8ea
# ╠═d3da7be0-aef5-4ea1-9655-00714ac25557
# ╠═f95c7d8c-5196-4e6b-88a0-bf9f0db626cb
# ╠═a3fcad3d-5d8f-4290-88d5-30764c2c689e
# ╠═edd3a37f-2ed3-4f9d-9275-58d6859a9396
# ╠═ef767260-419e-4029-b7cd-c202790668a5
# ╠═6f7b9b78-02af-43f1-8f71-8da6f8ac9aea
# ╠═47df8df1-3923-44a1-a19e-845246737b1e
# ╟─f5aadd23-1d7b-4c3b-be6e-111e431357e1
# ╟─f6a0b7bc-4722-49d9-98c8-37822febca88
# ╟─343af23b-4c4d-422b-81d2-4bc4e5407dac
# ╠═2ef0a234-499b-4e23-b7d7-c3fcadd14752
# ╠═6075b162-6315-4bd8-bdff-007f3a278b66
# ╠═c44ee57c-0cba-4436-9557-b0c7eaf77c62
# ╠═26d5c124-3da7-4a5a-b06e-38627b2dd8ac
# ╟─e8a84941-3ab0-461c-9ab8-cb0b5515989f
# ╠═9860d2fa-b497-4377-afe7-367b4a00e50d
# ╠═ef839605-88c5-4469-ae55-47961eb5417b
# ╠═635f6baa-e360-45b2-87de-fedf1ec52b4a
# ╟─65661116-c2a5-4684-aa1d-8514e6310025
# ╟─74330174-edfd-4e13-8bc1-f8c80c163be0
# ╠═1bf4c10a-1801-41be-b06f-677f44a156a7
# ╠═7758fb66-991d-49f7-b8f8-a3549fb0e340
# ╠═d61de21f-5d28-4bd9-8b41-0d0be92f9e76
# ╠═d54578a4-d0e6-4b18-bc13-477467b2a058
# ╠═79dd19b4-10cc-44a8-ba62-4a7ef1ceb752
# ╠═d154be95-8350-4c38-8b02-10595d9764cd
# ╠═958906a9-75c3-4ead-aafe-2596623b89c0
# ╟─35a249a3-7272-435a-a5d3-5e8ba8a655ca
# ╟─bec4f70a-7ff0-4c0e-8759-758a95831e46
# ╟─cd2e5706-bfc9-4fca-90bd-70460198c9ee
# ╠═187d4c9e-e366-4395-9b3e-b0cefbf9ce5d
# ╠═82731c8d-7819-42d3-afd1-eabfbad8303b
# ╠═da2ef327-9171-4daf-98e2-ed679d6f84e2
# ╟─79a60ed4-5281-4261-90fb-5f2bfc928758
# ╟─3dd1f51b-26e2-44f1-b754-fb58612e7d7c
# ╟─63a82ccb-21e4-4edc-81df-cd9f84953372
# ╠═647698ec-1f80-4ddd-ae98-f40a05ea75c6
# ╠═fbeb3c61-6c88-4aa5-9925-3510a00e366e
# ╠═9ac640ed-b400-46f8-89bc-650a5d2801ff
# ╠═6085715c-9ab0-4fe8-b159-9a814bc572e8
# ╠═7432a455-aff6-4a22-8576-9249f67b5dd7
# ╠═25fb28f6-4571-4b87-8a7d-9465eae537de
# ╠═c1ed6eb3-a0c7-484e-a511-2e13df3a2040
# ╠═185f315c-ccc9-4c9c-be91-f30c8046b27a
# ╠═8ab5fc32-41f1-4492-bc35-7d0cb5864162
# ╟─79978d9e-c28a-4787-9d6a-ac753331111e
# ╠═72c1cb62-58da-40c8-a5ff-5f9325360fe8
# ╠═02dcefce-3b27-441f-a76b-9dba2c7b2b72
# ╠═659c3d72-85e2-4f39-aa49-cbc83066c345
# ╠═a259c6c0-939e-4af0-a1d4-11d088b4c7db
# ╠═8effef36-3f6c-4179-877d-3f0e03863a22
# ╠═edd73ae8-6bf2-4585-9275-166e3ee7a017
# ╟─f2587d9c-8028-46f7-9610-869d9eb15c73
# ╟─117d30e6-1252-4198-b348-6a1e5e798070
# ╠═a62696dc-171a-4978-8de9-0ab643987b41
# ╠═07842e70-6c91-47cf-b480-28c690e4c0ab
# ╟─5342b18a-7fe2-46b4-a53f-91399797b971
# ╟─a26930b4-f8aa-41bf-8375-fac549980ca3
# ╠═21b17672-2800-4876-a83a-b04f5b94cf76
# ╠═bfdc099a-bdac-4b8f-8ef8-a1c2003c6d43
# ╠═b61af5cc-a240-4670-93d0-aeb01208d01d
# ╟─696e35a8-1ece-4a7b-a160-ec6d2a3134c0
# ╟─cb819012-a6cd-462e-bee1-c118ba8f3caf
# ╠═b672ad66-01a4-48b3-a169-02d97d4b9baa
# ╠═5b611e79-5689-4a33-929e-5c77dee7f958
# ╠═c429a2d2-69b9-437d-a138-efee4b118016
# ╠═36b197b3-1971-4c73-96ec-7370002ade1e
# ╠═e358c252-4592-4ae6-bd90-bf237dc3ee1d
# ╟─dfd216a0-817c-43b2-bb0a-e2f5bb28650d
# ╟─c736beb7-6714-4931-9e35-e452a9647682
# ╠═9b09f4bb-f7a9-460c-aa99-18a78f60ed4c
# ╠═e4cdffdb-33ca-4280-b8cf-965642bdc3af
# ╠═aa92101c-7cd1-4c80-8296-15fa126bac25
# ╠═f9f88f4c-9cf7-466b-b70a-5331eb2cbb5c
# ╟─f0ba714d-2710-4558-b078-24ae0faeb1e0
# ╠═0521760f-4ba0-4910-bf9d-8f345a5616a3
# ╠═0088977f-7cde-4c9b-9bce-c4977f62a3f7
# ╠═84352c40-13f2-45c3-9244-d996a67777b8
# ╟─81b627fb-263f-44fb-8e4e-4a4fe075dbc0
# ╠═c60041fa-242f-4847-8ba1-e0bb12c0aeb4
# ╠═c0fcf470-4f20-4bbc-adad-dbf82492b1fb
# ╠═5d5a0da9-07e0-4be1-ba9c-a854299cd23f
# ╠═2dedcfbb-7998-4767-a904-9930bf9bc796
# ╟─3be74cb9-4e2f-483a-ac57-0b80732218e0
# ╟─c2f25eac-7453-420a-bcda-ad70a438358f
# ╠═08c88bf1-72f9-4e54-926f-b8f8fdbb8179
# ╠═07971f8e-fd34-4292-a021-278b567ee3ef
# ╟─737189fe-e73d-4dbc-a172-da713925bd1d
# ╟─521c7938-d392-4831-b62b-bd4221cff162
# ╠═ddfa28f9-de7c-4faa-a998-bdfa1a17a223
# ╠═091fdf20-508c-48a1-aaa5-ad13722a540b
# ╠═70d90871-53ab-402a-9a6d-1dd727e5c6d0
# ╟─5838b73b-a044-4f63-b3b8-88c5b96e0f83
# ╟─27e4439a-9f40-40a9-8603-e80161da8004
# ╠═3c345c72-12cd-4573-a957-5bc5fe3caeb0
# ╠═81f5072b-46e2-466f-8a76-b984d7f3b75e
# ╠═d71d2ebc-0406-4bad-99f4-2ec06d7ec759
# ╟─14a79c53-1d0a-438e-8a9b-e7dafbef1322
# ╟─7a05752f-522c-4f5e-84fc-bd9624deb07e
# ╠═c197c2fd-cd78-4aa6-83c1-bb34d6579c80
# ╠═dc99a9c2-cb70-4498-b9ed-6295fff11884
# ╠═a34e91e7-927e-4b0a-b72b-0813e098f000
# ╠═516a6341-aa4d-4811-aaa1-c65ed92b0357
# ╠═ff34f0e0-dc07-467a-88cb-6d287ba4463b
# ╠═774c9f2b-3e2f-4f74-bf22-28745063cfae
# ╟─38e5cf39-0766-400b-9312-e39b673faac6
# ╠═f1b551ba-4f27-4bec-af09-7554c2e76045
# ╠═6e8dead0-6af0-4324-928d-e19b295c9b5b
# ╠═623332dc-d56a-478e-84ac-32fe9123c0c2
# ╠═61ec2044-e93e-4a70-8408-8cd48cc4f784
# ╟─140c3020-58b1-439b-9772-7b17b5915b40
# ╟─10632c4e-7aa0-4f99-a9ff-39ccad2da377
# ╟─7867678b-5910-45a5-a8fd-59ace4d0dc7b
# ╟─d02fe0a3-3523-4239-9b74-bf4e00b5e891
# ╠═94e99222-efff-400d-b8b7-d378c53c8e9d
# ╟─8bcd6ea1-6711-4a0c-8f1c-bba12e843808
# ╟─37d4a03a-af97-4208-bfa1-6bb057f0f988
# ╠═97929c85-54c0-4976-95b6-d70364c68035
# ╠═6a292063-5989-4058-ab5c-898b1de0de73
# ╠═06427107-e04a-44d0-9db1-76a9c7519895
# ╠═f43d6358-5f1f-40e9-896f-37038ad04986
# ╠═072e8834-0a19-456a-b818-f436a847490b
# ╟─0859eeeb-0dbf-4f39-a7a4-a5f828726b16
# ╠═50751fc6-5704-4487-ba2f-9f37c21fbdfc
# ╠═7a96bdd1-65b5-48cf-8ebc-36f0ba216965
# ╠═31cdcfd6-70b1-4bef-aecd-78c5d359540c
# ╠═38185599-aa95-4716-9b2e-1af3b2548396
# ╠═da3ec2a7-109b-4f8e-bd5e-521e257b8693
# ╟─90ac16c3-37d4-42ae-a9ed-4572c49397dc
# ╟─27c05748-4570-4420-af08-15fd2a31a373
# ╟─05fd1ff1-b47d-4452-b0c0-b4a39a5b3d7e
# ╠═0c614e7c-27d9-45cf-90a2-699a02493a72
# ╠═de956d60-60b6-47cf-baa6-0cc65ac45877
# ╠═bc4e06d3-1429-40f2-a2cc-d8c5c2e26872
# ╠═e8cb0195-51d7-41e9-9e69-7c79e2f5d35f
# ╠═27a240c4-b201-4a49-b784-c454ff0f1575
# ╠═6717ffeb-626b-4ec0-a70d-3727dc8a4f0e
# ╟─04f09813-3514-4e81-93ce-a3bf28610537
# ╠═e0614b11-3e67-4ce5-90ab-14e245449fcb
# ╟─71a51430-9b8c-4f22-b41d-3a1532df159c
# ╟─e6439db0-d98a-4ae5-b706-c606f1caea4a
# ╠═46433eaf-fc72-4f4f-8dd7-811f4579b5f0
# ╟─dee2f972-3b85-473b-adc1-5c3888c5daa0
# ╠═be8235a9-2633-41ac-a6d1-d2330d7146f9
# ╠═f020f165-37f9-45ed-8d21-1e8fc8e1591a
# ╠═9e2fbbbb-5c69-4ed2-887f-4913db2d0153
# ╠═5693bae3-e676-497c-baef-c84472270cef
