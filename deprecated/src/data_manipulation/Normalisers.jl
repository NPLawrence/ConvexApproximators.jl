abstract type AbstractNormaliser end

function normalise(normaliser::AbstractNormaliser, z, name)
    error("Define method `normalise` for $(typeof(normaliser))")
end

function unnormalise(normaliser::AbstractNormaliser, z, name)
    error("Define method `unnormalise` for $(typeof(normaliser))")
end


"""
Identity normaliser, i.e., does not affect at all.
Usually used for debugging or comparison of the performance of normalisation.
"""
struct IdentityNormaliser <: AbstractNormaliser
end

function normalise(normaliser::IdentityNormaliser, z, name)
    z
end

function unnormalise(normaliser::IdentityNormaliser, z, name)
    z
end


struct StandardNormalDistributionNormaliser <: AbstractNormaliser
    mean_nt
    std_nt
    function StandardNormalDistributionNormaliser(data::xufData)
        @unpack x, u, f = data
        mean_nt = (; x=mean(x), u=mean(u), f=mean(f))
        std_nt = (; x=std(x), u=std(u), f=std(f))
        new(mean_nt, std_nt)
    end
end

"""
z ∈ ℝ^l or ℝ^(l×d)
"""
function normalise(normaliser::StandardNormalDistributionNormaliser, z::Convex.AbstractExpr, name)
    # TODO: unify this method to normalise(normaliser::StandardNormalDistributionNormaliser, z, name)
    @unpack mean_nt, std_nt = normaliser
    (z - getproperty(mean_nt, name)) ./ getproperty(std_nt, name)
end

function normalise(normaliser::StandardNormalDistributionNormaliser, z, name)
    @unpack mean_nt, std_nt = normaliser
    (z .- getproperty(mean_nt, name)) ./ getproperty(std_nt, name)
end

function unnormalise(normaliser::StandardNormalDistributionNormaliser, z, name)
    @unpack mean_nt, std_nt = normaliser
    (z .* getproperty(std_nt, name)) .+ getproperty(mean_nt, name)
end


"""
DO NOT USE `min.(x...)` instead of `minimum(_xs, dims=2)[:]`; horribly slow.
"""
struct MinMaxNormaliser <: AbstractNormaliser
    min_nt
    max_nt
    function MinMaxNormaliser(data::xufData)
        @unpack x, u, f = data
        _xs = hcat(x...)
        _us = hcat(u...)
        _fs = hcat(f...)
        min_nt = (; x=minimum(_xs, dims=2)[:], u=minimum(_us, dims=2)[:], f=minimum(_fs, dims=2)[:])  # vectorise
        max_nt = (; x=maximum(_xs, dims=2)[:], u=maximum(_us, dims=2)[:], f=maximum(_fs, dims=2)[:])  # vectorise
        new(min_nt, max_nt)
    end
    function MinMaxNormaliser(data::xurx_nextData)
        @unpack x, u, r, x_next = data
        _xs = hcat(x...)
        _us = hcat(u...)
        _rs = hcat(r...)
        _x_nexts = hcat(x_next...)
        # min_nt = (; x=minimum(_xs, dims=2)[:], u=minimum(_us, dims=2)[:], r=minimum(_rs, dims=2)[:], x_next=minimum(_x_nexts, dims=2)[:])  # vectorise
        # max_nt = (; x=maximum(_xs, dims=2)[:], u=maximum(_us, dims=2)[:], r=maximum(_rs, dims=2)[:], x_next=maximum(_x_nexts, dims=2)[:])  # vectorise
        # TODO: f should be normalised by r...?
        min_nt = (; x=minimum(_xs, dims=2)[:], u=minimum(_us, dims=2)[:], f=minimum(_rs, dims=2)[:])  # vectorise
        max_nt = (; x=maximum(_xs, dims=2)[:], u=maximum(_us, dims=2)[:], f=maximum(_rs, dims=2)[:])  # vectorise
        new(min_nt, max_nt)
    end
    function MinMaxNormaliser(min_nt, max_nt)
        new(min_nt, max_nt)
    end
end

"""
z ∈ ℝ^l or ℝ^(l×d)

each element of z or z[:, i] (if z is Matrix) is mapped from [z_min, z_max] to [0, 1]
"""
function normalise(normaliser::MinMaxNormaliser, z::Convex.AbstractExpr, name)
    @unpack min_nt, max_nt = normaliser
    (z - getproperty(min_nt, name)) ./ (getproperty(max_nt, name) - getproperty(min_nt, name))
end

"""
# Note
`normalise` has two methods for AbstractArray and AbstractMatrix;
if you adopt only one method with broadcasting (e.g., `.-`),
when `z`'s dimension is one, it gives a result even if
the normaliser is defined for `m`-dimensional data (`m > 1`).
"""
function normalise(normaliser::MinMaxNormaliser, z::AbstractArray, name)
    @unpack min_nt, max_nt = normaliser
    (z - getproperty(min_nt, name)) ./ (getproperty(max_nt, name) - getproperty(min_nt, name))
end

function normalise(normaliser::MinMaxNormaliser, z::AbstractMatrix, name)
    @unpack min_nt, max_nt = normaliser
    (z .- getproperty(min_nt, name)) ./ (getproperty(max_nt, name) - getproperty(min_nt, name))
end

"""
z ∈ ℝ^l or ℝ^(l×d)

each element of z or z[:, i] (if z is Matrix) is mapped from [0, 1] to [z_min, z_max]
"""
function unnormalise(normaliser::MinMaxNormaliser, z, name)
    @unpack min_nt, max_nt = normaliser
    getproperty(min_nt, name) .+ (z .* (getproperty(max_nt, name) - getproperty(min_nt, name)))
end