module ParametrisedConvexApproximators

# using Debugger  # tmp
using Flux
using Random
using Transducers
using Convex
using UnPack
using RecipesBase: AbstractPlot, plot!

# data structure
export xufData
export partitionTrainTest
# approximators
export FNN
export MA, LSE
export PMA, PLSE
# training
export train_approximator!
export plot_approx!


include("approximators/approximators.jl")
include("data_manipulation/data_manipulation.jl")
include("training/training.jl")
include("visualisation/visualisation.jl")


end  # module