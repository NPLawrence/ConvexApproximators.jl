using ParametrisedConvexApproximators
const PCA = ParametrisedConvexApproximators
using Test

using Flux
using Transducers
using Convex
using ForwardDiff
using Plots


"""
test function
"""
function f(x, u)
    0.5 * (-x'*x + u'*u)
end

function supervised_learning!(approximator, xuf_data)
    @show approximator |> typeof
    xuf_data_train, xuf_data_test = PCA.partitionTrainTest(xuf_data)
    PCA.train_approximator!(approximator, xuf_data_train, xuf_data_test;
                            epochs=300,
                           )
    println("No error while training the approximator")
end

function test(approximator, _xs, _us)
    @show approximator |> typeof
    d = size(_xs)[2]
    m = size(_us)[1]
    _x = _xs[:, 1]
    _u = _us[:, 1]
    u_convex = Convex.Variable(length(_us[:, 1]))
    u_convex.value = _u
    @testset "infer size check" begin
        @test approximator(_xs, _us) |> size == (1, d)
        @test approximator(_x, _u) |> size == (1,)
    end
    @testset "Convex.Variable evaluation check" begin
        @test approximator(_x, u_convex.value) ≈ approximator(_x, _u)
        @test evaluate.(approximator(_x, u_convex)) ≈ approximator(_x, _u)
    end
end

function generate_approximators(n, m, d)
    i_max = 20
    h_array = [16, 16]
    T = 1e-1
    act = Flux.leakyrelu
    u_is = range(-1, 1, length=i_max) |> Map(_u_i -> [_u_i]) |> collect  # to make it a matrix
    # u_star_is = u_is |> Map(u_i -> (x -> f_partial_u(x, u_i))) |> collect
    u_star_is = u_is |> Map(u_i -> (x -> ForwardDiff.gradient(u -> f(x, u), u_i))) |> collect
    α_is = 1:i_max |> Map(i -> rand(n+m)) |> collect
    β_is = 1:i_max |> Map(i -> rand(1)) |> collect

    # test
    ma = MA(α_is, β_is)
    lse = LSE(α_is, β_is, T)
    pma_basic = PMA(n, m, i_max, h_array, act)
    pma_theoretical = PMA(n, m, u_is, u_star_is, f)
    plse = PLSE(n, m, i_max, T, h_array, act)
    approximators = (;
                     ma=ma,
                     lse=lse,
                     pma_basic=pma_basic,
                     # pma_theoretical=pma_theoretical,  # TODO
                     plse=plse,
                    )  # NT
    _approximators = Dict(zip(keys(approximators), values(approximators)))  # Dict
end

function generate_data(n, m, d, xlim, ulim)
    xs = 1:d |> Map(i -> xlim[1] .+ (xlim[2]-xlim[1]) .* rand(n)) |> collect
    us = 1:d |> Map(i -> ulim[1] .+ (ulim[2]-ulim[1]) .* rand(m)) |> collect
    fs = zip(xs, us) |> MapSplat((x, u) -> f(x, u)) |> collect
    xuf_data = PCA.xufData(xs, us, fs)
end

# function plot_figure!(fig, approx, xlim, ulim; Δx=0.1, Δu=0.1, kwargs...)
#     func(x, u) = approx([x], [u])[1]
#     plot!(fig,
#           (xlim[1]):Δx:(xlim[2]), (ulim[1]):Δx:(ulim[2]), func;
#           st=:surface,
#           kwargs...,
#          )
# end

@testset "approximators" begin
    dir_log = "figures/test"
    mkpath(dir_log)
    n, m, d = 1, 1, 1000
    _approximators = generate_approximators(n, m, d)
    approximators = (; _approximators...)  # NT
    xlim = (-5, 5)
    ulim = (-5, 5)
    xuf_data = generate_data(n, m, d, xlim, ulim)
    _xs = hcat(xuf_data.x...)
    _us = hcat(xuf_data.u...)
    # test
    print("Testing basic functionality...")
    approximators |> Map(approx -> test(approx, _xs, _us)) |> collect
    # training
    print("Testing supervised_learning...")
    approximators |> Map(approx -> supervised_learning!(approx, xuf_data)) |> collect
    # figures
    figs_true = 1:length(approximators) |> Map(approx -> plot(;
                                                                xlim=(-5, 5), ylim=(-5, 5), zlim=(-25, 25),
                                                               )) |> collect
    _ = zip(figs_true, approximators) |> MapSplat((fig, approx) -> plot_approx!(fig, (x, u) -> [f(x, u)], xlim, ulim)) |> collect
    figs_approx = 1:length(approximators) |> Map(approx -> plot(;
                                                                xlim=(-5, 5), ylim=(-5, 5), zlim=(-25, 25),
                                                               )) |> collect
    _ = zip(figs_approx, approximators) |> MapSplat((fig, approx) -> plot_approx!(fig, approx, xlim, ulim)) |> collect
    # subplots
    figs = zip(figs_approx, figs_true) |> MapSplat((fig_approx, fig_true) -> plot(fig_approx, fig_true; layout=(2, 1),)) |> collect
    # save figs
    _ = zip(figs, _approximators) |> MapSplat((fig, _approx) -> savefig(fig, joinpath(dir_log, "$(_approx[1]).png"))) |> collect
end