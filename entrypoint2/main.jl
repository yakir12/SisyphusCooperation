import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Dates, LinearAlgebra, LazyArtifacts
using CSV, DataFramesMeta

df = DataFrame(CSV.File(artifact"SisyphusCooperationProcessed/processeddata/csvs/data.csv"))

