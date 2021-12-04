# Induced velocities

velocity!(F, r, horseshoe :: Horseshoe, Γ :: Real, V_hat, finite_core = false) =
    F[:] = velocity(r, horseshoe, Γ, V_hat)

function induced_velocity(r, horseshoes, Γs, U_hat) 
    # @timeit "Induced Velocity" sum(x -> velocity(r, x[1], x[2], U_hat), zip(horseshoes, Γs))
    F = zeros(eltype(r), 3)
    for (hs, Γ) in zip(horseshoes, Γs)
        F += velocity(r, hs, Γ, U_hat)
    end
    F
end

velocity(hs, Γs, r, n, U_hat, Ω_hat) = @timeit "Velocity" dot(induced_velocity(r, hs, Γs, -U_hat) - (U_hat + Ω_hat × r), n)

# Residual computation
aerodynamic_residual!(R_A, horseshoes, Γs, U_hat, Ω_hat) = @timeit "Aerodynamic Residual" map!(hs -> velocity(horseshoes, Γs, horseshoe_point(hs), horseshoe_normal(hs), U_hat, Ω_hat), R_A, horseshoes)