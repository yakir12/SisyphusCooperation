using Autotrack, DataFramesMeta
using LazyArtifacts, Dates

using Autotrack, VideoIO, CSV, , Dierckx, StaticArrays, CameraCalibrations
using ThreadsX

#
debug = false # set to true if you want to save video snippets of the tracked beetles. This helps assesing the quality of the auto-tracking.
checker = 4.1 # in cm

include("../entrypoint1/utils.jl")

df = DataFrame(CSV.File(artifact"SisyphusCooperation/rawdata/csvs/runs.csv", types = Dict("start" => Time, "stop" => Time)))
