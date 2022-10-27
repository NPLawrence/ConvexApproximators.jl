"""
Log-sum-exp neural network [1].

# Note
If you specify `n` or `m`, it can also be regarded as bivariate function.

# Variables
x ∈ ℝ^n
u ∈ ℝ^m
z = [xᵀ, uᵀ]ᵀ ∈ ℝ^(n+m)  # l = n+m
α_is: a vector of subgradients, i.e., α_is[i] ∈ ℝ^(n+m).
β_is: a vector of bias terms, i.e., β_is[i] ∈ ℝ.
T > 0: temperature

# References
[1] G. C. Calafiore, S. Gaubert, and C. Possieri, “Log-Sum-Exp Neural Networks and Posynomial Models for Convex and Log-Log-Convex Data,” IEEE Transactions on Neural Networks and Learning Systems, vol. 31, no. 3, pp. 827–838, Mar. 2020, doi: 10.1109/TNNLS.2019.2910417.
"""
struct LSE <: ConvexApproximator
    l::Int  # n+m
    n::Int  # the first variable for bivariate function
    m::Int  # the second variable for bivariate function
    i_max::Int
    T::Real
    _α_is::Matrix
    _β_is::Matrix
    function LSE(α_is::Vector, β_is::Vector, T; n=nothing, m=nothing)
        @assert T > 0
        l, i_max, _α_is, _β_is = _construct_convex_approximator(α_is, β_is)
        if n != nothing && m != nothing
            @assert l == n + m
        elseif n != nothing
            m = l - n
            @assert m > 0
        elseif m != nothing
            n = l - m
            @assert n > 0
        end
        new(l, n, m, i_max, T, _α_is, _β_is)
    end
end
Flux.@functor LSE (_α_is, _β_is,)


"""
Considering univariate function approximator
"""
function (nn::LSE)(z::AbstractArray)
    is_vector = length(size(z)) == 1
    @unpack T = nn
    z_affine = affine_map(nn, z)
    _res = T * Flux.logsumexp((1/T)*z_affine; dims=1)
    res = is_vector ? reshape(_res, 1) : _res
end

# function (nn::LSE)(z::Convex.AbstractExpr)
#     @unpack T = nn
#     z_affine = affine_map(nn, z)
#     _res = [T * Convex.logsumexp((1/T)*z_affine)]
# end

"""
Considering bivariate function approximator
"""
function (nn::LSE)(x::AbstractArray, u::AbstractArray)
    nn(vcat(x, u))
end

# function (nn::LSE)(x::AbstractArray, u::Convex.AbstractExpr)
#     nn(vcat(Convex.Constant(x), u))  # if x is a ComponentArray, vcat(⋅, ⋅) becomes ambiguous
# end
