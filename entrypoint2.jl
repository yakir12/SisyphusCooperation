using Dates, LinearAlgebra, LazyArtifacts
using CSV, DataFramesMeta

include("utils.jl")

df = DataFrame(CSV.File(artifact"SisyphusCooperationProcessed/processeddata/csvs/data.csv"))

