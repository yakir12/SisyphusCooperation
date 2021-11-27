import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Dates, LinearAlgebra, LazyArtifacts
using CSV, DataFramesMeta

df = DataFrame(CSV.File(artifact"SisyphusCooperation/processeddata/csvs/data.csv"))

