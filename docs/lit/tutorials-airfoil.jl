# ## Objectives
#
# Here we will teach you the basic functionality of AeroMDAO by showing you how to perform an aerodynamic analysis of an airfoil. 
# Specifically we will:
# 1. Compute the coordinates of a NACA 4-digit series airfoil.
# 2. Plot its camber, thickness, upper and lower surface representations.
# 3. Perform an aerodynamic analysis at a given angle of attack.
# 4. Plot its aerodynamic properties.
# For this, we will need to import some packages which will be convenient for plotting.
using AeroMDAO      # Main package
using Plots         # Plotting library
gr(dpi = 300)       # Plotting backend
using LaTeXStrings  # For LaTeX printing in plots

# ## Your First Airfoil
#
# You can define a NACA-4 airfoil using the following function. To analyze our airfoil, we must convert the coordinates into a `Foil` type defined in `AeroMDAO`.
airfoil = naca4((2,4,1,2), 60)

# You can access the abscissa and ordinates as the following fields.
airfoil.x, airfoil.y

# You can access the coordinates by calling the following function.
coordinates(airfoil)

# ### Geometric Representations
# You can convert these coordinates into the camber-thickness representation.
xcamthick = camber_thickness(airfoil, 60)

# You can also do the inverse transformation.
coords = camber_thickness_to_coordinates(xcamthick[:,1], xcamthick[:,2], xcamthick[:,3])

# You can split the coordinates into their upper and lower surfaces.
upper, lower = split_surface(airfoil);

x_upper, y_upper = @views upper[:,1], upper[:,2]
x_lower, y_lower = @views lower[:,1], lower[:,2];

# ### Plotting
# Let's plot everything! 

## Plot object
af_plot = plot(aspect_ratio = 1, xlabel=L"(x/c)", ylabel = L"y")

## Upper surface
plot!(upper[:,1], upper[:,2], label = "$(airfoil.name) Upper",
      ls = :solid, lw = 2, c = :cornflowerblue)

## Lower surface
plot!(lower[:,1], lower[:,2], label = "$(airfoil.name) Lower",
      ls = :solid, lw = 2, c = :orange)

## Camber
plot!(xcamthick[:,1], xcamthick[:,2], label = "$(airfoil.name) Camber",
      ls = :dash, lw = 2, c = :burlywood3)

## Thickness
plot!(xcamthick[:,1], xcamthick[:,3], label = "$(airfoil.name) Thickness",
      ls = :dash, lw = 2, c = :grey)

# ## Your First Doublet-Source Analysis
# 
# Now we have an airfoil, and we would like to analyze its aerodynamic characteristics. The potential flow panel method for inviscid analyses of airfoils, which you may have studied in your course in aerodynamics, provides decent estimations of the lift generated by the airfoil.

# Our analysis also requires boundary conditions, which is the freestream flow defined by a magnitude ``V_\infty`` and angle of attack ``\alpha``. We provide these to the analysis by defining variables and feeding them to a `Uniform2D` type, corresponding to uniform flow in 2 dimensions.
V       = 1.0
alpha   = 4.0
uniform = Uniform2D(V, alpha)

# Now that we have our airfoil and boundary conditions, we can call the `solve_case()` function, which in this case has an associated method with the specification of ``n`` panels given by the optional argument `num_panels`, which is 60 by default. This will run the analysis and return a system which can be used to obtain the aerodynamic quantities of interest and post-processing.
system  = @time solve_case(
                     airfoil, uniform;
                     num_panels = 80
                    );

## The following functions compute the quantities of interest, such as the inviscid edge velocities, lift coefficient, and the sectional lift, moment, and pressure coefficients.
panels     = system.surface_panels
@time u_es = surface_velocities(system);
@time cl   = lift_coefficient(system)
@time cls, cms, cps = surface_coefficients(system)

# Note the difference between the lift coefficient computed and the sum of the sectional lift coefficients; this is due to numerical errors in the solution procedure and modeling.
cl, sum(cls)

#md # !!! info
#md #     Support for drag prediction with boundary layer calculations will be added soon. For now, try out the amazing [Webfoil](http://webfoil.engin.umich.edu/) developed by the MDOLab at University of Michigan -- Ann Arbor!

# ### Visualization
# 
# Let's see what the pressure and lift distribution curves look like over the airfoil. AeroMDAO provides more helper functions for post-processing data.
pts      = collocation_point.(panels) # Collocation point
tangents = panel_tangent.(panels)     # Tangents
normals  = panel_normal.(panels)      # Normals
locs     = panel_location.(panels);   # Upper or lower surface

# You can make your plots fancier by segregating the values depending on the locations of the panels.
get_surface_values(panels, vals, surf = "lower") = [ (collocation_point(panel)[1], val) for (val, panel) in zip(vals, panels) if panel_location(panel) == surf ]

cp_lower = get_surface_values(panels, cps, "lower")
cp_upper = get_surface_values(panels, cps, "upper");

# Now let's plot the results.

## Pressure coefficients
plot(yflip = true, xlabel = L"(x/c)", ylabel = L"C_p")
plot!(cp_upper, label = "Upper",
      ls = :dash, lw = 2, c = :cornflowerblue)
plot!(cp_lower, label = "Lower",
      ls = :dash, lw = 2, c = :orange)
plot!(x_upper, -y_upper, label = "$(airfoil.name) Upper", 
      ls = :solid, lw = 2, c = :cornflowerblue)
plot!(x_lower, -y_lower, label = "$(airfoil.name) Lower", 
      ls = :solid, lw = 2, c = :orange)

#
## Lift coefficients
cl_upper = get_surface_values(panels, cls, "upper")
cl_lower = get_surface_values(panels, cls, "lower")

cl_plot = plot(xlabel = L"(x/c)", ylabel = L"C_l")
plot!(x_upper, y_upper, lw = 2, c = :cornflowerblue, label = "Upper")
plot!(x_lower, y_lower, lw = 2, c = :orange, label = "Lower")
plot!(cl_upper, ls = :dash, lw = 2, c = :cornflowerblue, label = L"$C_l$ Upper")
plot!(cl_lower, ls = :dash, lw = 2, c = :orange, label = L"$C_l$ Lower")

#
## Moment coefficients
cm_upper = get_surface_values(panels, cms, "upper")
cm_lower = get_surface_values(panels, cms, "lower")

cm_plot = plot(xlabel = L"(x/c)", ylabel = L"C_m")
plot!(x_upper, y_upper, lw = 2, c = :cornflowerblue, label = "Upper")
plot!(x_lower, y_lower, lw = 2, c = :orange, label = "Lower")
plot!(cm_upper, ls = :dash, lw = 2, c = :cornflowerblue, label = L"$C_m$ Upper")
plot!(cm_lower, ls = :dash, lw = 2, c = :orange, label = L"$C_m$ Lower")


# Great! We've created our first airfoil and run an aerodynamic analysis in 2 dimensions. 