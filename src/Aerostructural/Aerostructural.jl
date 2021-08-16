module Aerostructural

using StaticArrays
using LinearAlgebra
using Einsum
using ComponentArrays
using TimerOutputs

import ..AeroMDAO: freestream_to_cartesian, VLMSystem, VLMState, VLMSurface, update_velocity!, compute_influence_matrix!, compute_boundary_condition!, generate_system!, update_circulations!, compute_surface_forces!, compute_surface_moments!, compute_farfield_forces!, total_force, surfaces, AIC, RHS, name, horseshoes, make_panels, horseshoe_line, horseshoe_point, bound_leg_center, quasi_steady_freestream, influence_coefficient, influence_matrix, boundary_condition, nearfield_forces, surface_forces, tube_stiffness_matrix
import ..AeroMDAO.VortexLattice: velocity

## Aerodynamic analysis
#==========================================================================================#

include("aerodynamics.jl")

## Structural analysis
#==========================================================================================#

include("structures.jl")

## Load-displacement transfer mechanisms
#==========================================================================================#

include("transfers.jl")

## Weights, engine, and fuel loads
#==========================================================================================#

# ???

## Coupled residual systems
#==========================================================================================#

include("residuals.jl")

end