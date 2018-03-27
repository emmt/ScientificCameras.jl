module Calibration

export
    CalibrationData,
    fit

struct CalibrationData{T<:AbstractFloat}
    cnt::Int   # number of samples
    avg::T     # average value
    sqr::T     # average squared value
    fct::T     # brightness factor, e.g. 1 for flat field, 0 for dark or bias
    Δt::T      # exposure time
end

"""

The parameters are `[a, b, c, g, σ]` and the expectation and variance of
the data are given by:

    E(d|x) = (s*a + c)*Δt/g + b
    Var(d|x) = ((s*a + c)*Δt + σ²)/g²

with `d` the raw pixel data, `s = 1` for flat images and `s = 0` for bias and
dark images, `a` the flat flux times the quantum efficiency, `c` the dark
current, `Δt` the exposure time, `b` the bias, `g` the conversion gain and `σ`
the standard deviation of the readout noise.  Here, `a` and `c` are in
photo-electrons per pixel per unit of time, the gain `g` is en photo-electrons
per ADU (analog-digital units), `b` is in ADU per pixel per frame, and `σ` is
in photo-electrons per pixel per frame.

A more convenient set of parameters for the fit `[a',b,c',g,v']` where `a' =
a/g`, `c' = c/g` and `v' = σ²/g`

"""
function fit(::Type{Val{:detector_model_abc}},
             dat::AbstractVector{CalibrationData{T}},
             wgt::AbstractVector{T} = ones(T, length(dat));
             nonnegative::Bool = false) where {T<:AbstractFloat}

    n = length(dat)
    @assert length(wgt) == n
    A11 = A21 = A31 = zero(T)
    A22 = A32 = zero(T)
    A33 = zero(T)
    b1 = b2 = b3 = zero(T)
    γ = zero(T)
    @inbounds @simd for i in eachindex(dat, wgt)
        d = dat[i]
        w = T(d.cnt)*wgt[i] # total weight

        # Basis functions.
        h1 = d.fct*d.Δt
        h2 = one(T)
        h3 = d.Δt

        # Update coefficients of LHS matrix.
        h1_w, h2_w, h3_w = h1*w, h2*w, h3*w
        A11 += h1_w*h1
        A21 += h2_w*h1
        A31 += h3_w*h1
        A22 += h2_w*h2
        A32 += h3_w*h2
        A33 += h3_w*h3

        # Update coefficients of RHS vector.
        b1 += h1_w*d.avg
        b2 += h2_w*d.avg
        b3 += h3_w*d.avg

        # Update constant term.
        γ += w*d.sqr
    end

    # Solve the normal equations (without constraints and using fast "static
    # arrays").
    q0, s0 = solve3(A11, A21, A31, A22, A32, A33, b1, b2, b3)
    qmax, x1, x2, x3 = q0, s0[1], s0[2], s0[3]

    # Check whether solving the unsconstrained problem yields a feasible
    # solution.
    if nonnegative && (x1 < zero(T) || x3 < zero(T))
        # Assuming inactive constraints yields an unfeasible model.  We
        # have to determine which constraints are active.  We first assume
        # that both constraints are active.
        q1, s1 = solve1(A22, b2)
        qmax, x1, x2, x3 = q1, zero(T), s1[1], zero(T)
        # Second, assume only x1 is 0.
        q2, s2 = solve2(A22, A32, A33, b2, b3)
        if q2 > qmax && s2[2] ≥ zero(T)
            qmax, x1, x2, x3 = q2, zero(T), s2[1], s2[2]
        end
        # Third, assume only x3 is 0.
        q3, s3 = solve2(A11, A21, A22, b1, b2)
        if q3 > qmax && s3[1] ≥ zero(T)
            qmax, x1, x2, x3 = q2, s3[1], s3[2], zero(T)
        end
    end
    return γ - qmax/2, (x1, x2, x3)
end

# Idem but assume dark-current is zero.
function fit(::Type{Val{:detector_model_ab}},
             dat::AbstractVector{CalibrationData{T}},
             wgt::AbstractVector{T} = ones(T, length(dat));
             nonnegative::Bool = false) where {T<:AbstractFloat}

    n = length(dat)
    @assert length(wgt) == n
    A11 = A21 = zero(T)
    A22 = zero(T)
    b1 = b2 = zero(T)
    γ = zero(T)
    @inbounds @simd for i in eachindex(dat, wgt)
        d = dat[i]
        w = T(d.cnt)*wgt[i] # total weight

        # Basis functions.
        h1 = d.fct*d.Δt
        h2 = one(T)

        # Update coefficients of LHS matrix.
        h1_w, h2_w = h1*w, h2*w
        A11 += h1_w*h1
        A21 += h2_w*h1
        A22 += h2_w*h2

        # Update coefficients of RHS vector.
        b1 += h1_w*d.avg
        b2 += h2_w*d.avg

        # Update constant term.
        γ += w*d.sqr
    end

    # Solve the normal equations (without constraints and using fast "static
    # arrays").
    q0, s0 = solve2(A11, A21, A22, b1, b2)
    qmax, x1, x2, x3 = q0, s0[1], s0[2], zero(T)

    # Check whether solving the unsconstrained problem yields a feasible
    # solution.
    if nonnegative && x1 < zero(T)
        # Assuming inactive constraints yields an unfeasible model.  The only
        # other possibility is to have x1 = 0.
        q1, s1 = solve1(A22, b2)
        qmax, x1, x2, x3 = q1, zero(T), s1[1], zero(T)
    end
    return γ - qmax/2, (x1, x2, x3)
end

#------------------------------------------------------------------------------
# UTILITIES

"""
```julia
solve1(A11, b1) -> q, x
solve2(A11, A21, A22, b1, b2) -> q, x
solve3(A11, A21, A31, A22, A32, A33, b1, b2, b3) -> q, x
```

yields the maximal score `q = 2b'⋅x - x'⋅A⋅x` and the corresponding parameters
`x` where `A` is a symmetric positive definite matrix of small size `n×n` and
`b` a vector of length `n`.  For instance, `A` and `b` are the left hand-side
matrix and right hand-side vector of a linear least squares problem.

Only the lower-triangular part of `A` is specified.

"""
function solve1(A11::T, b1::T) where {T <: AbstractFloat}
    x1 = b1/A11
    return x1*b1, (x1,)
end

function solve2(A11::T, A21::T, A22::T,
                b1::T, b2::T) where {T <: AbstractFloat}
    A = SMatrix{2,2,T,4}(A11, A21,
                         A21, A22)
    b = SVector{3,T}(b1, b2)
    x = A\b
    return (x[1]*b1 + x[2]*b2), x
end

@doc @doc(solve1) solve2

function solve3(A11::T, A21::T, A31::T, A22::T, A32::T, A33::T,
                b1::T, b2::T, b3::T) where {T <: AbstractFloat}
    A = SMatrix{3,3,T,9}(A11, A21, A31,
                         A21, A22, A32,
                         A31, A32, A33)
    b = SVector{3,T}(b1, b2, b3)
    x = A\b
    return (x[1]*b1 + x[2]*b2 + x[3]*b3), x
end

@doc @doc(solve1) solve3

end # module
