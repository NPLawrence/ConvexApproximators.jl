module ParametrisedConvexApproximators

using Flux
using UnPack
# using Convex
# using SCS  # 211207; currently not compatible with apple silicon
# using Optim
using Transducers
using Random


# approximators
export AbstractApproximator, FNN
export ConvexApproximator, MA, LSE
export ParametrisedConvexApproximators, PMA, PLSE
export PICNN, project_nonnegative!
# export optimise, number_of_parameters
# data manipulation
export partitionTrainTest


# approximators
include("approximators/approximators.jl")
# include("optimise.jl")
include("data_manipulation/data_manipulation.jl")


end  # module
