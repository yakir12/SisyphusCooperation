import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Dates, LinearAlgebra, LazyArtifacts
using Autotrack, VideoIO, CSV, DataFramesMeta, Dierckx, StaticArrays, CameraCalibrations
using ConfParser
using ProgressMeter

const conf = ConfParse("configuration.ini")
parse_conf!(conf)

include("utils.jl")
include("calibrations.jl")

df = CSV.read(artjoin("runs.csv"), DataFrame, types = Dict("start" => Time, "stop" => Time))
foreach(artjoin, df.file)

calibs = CSV.read(artjoin("calibrations.csv"), DataFrame)
@rtransform!(calibs, :extrinsic = tosecond(:extrinsic), :file = artjoin(:calibration_ID))
@select!(calibs, :calibration_ID, :calibration = time2calib.(:file, :extrinsic))

df = innerjoin(df, calibs, on = "calibration_ID")
select!(df, Not("calibration_ID"))
@rtransform!(df, :duration = tosecond(:stop - :start))
@rtransform!(df, :guess = ismissing(:dropoffx) ? nothing : tuple(:dropoffx, :dropoffy))

@info "Tracking videos. This will take some time…"
results = joinpath("..", "results")
tracks = joinpath(results, "tracks")
mkpath(tracks)
n = nrow(df)
p = Progress(n)
Threads.@threads for row in eachrow(df)
  track = get_track(row.rownumber, row.file, row.start, row.stop, row.calibration, row.guess)
  t = range(0, row.duration, 1000)
  xy = track.(t)
  (t = t, x = first.(xy), y = last.(xy)) |> CSV.write(joinpath(tracks, string(row.rownumber, ".csv")))
  next!(p)
end

# tracks = DataFrame((rownumber = parse(Int, first(splitext(basename(file)))), xyt = CSV.File(file)) for file in readdir("../results/tracks", join = true)) 
# @rtransform!(tracks, :l = maximum(sqrt(xy.x^2 + xy.y^2) for xy in :xyt)) 
# sort!(tracks, :l)
# x = @rsubset(df, :rownumber ∈ tracks.rownumber[1:10])
# select!(x, Cols(:file, :start, :stop, :rownumber))
