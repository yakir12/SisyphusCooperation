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
if !all(artifact_downloaded, df.file)
  @info "Downloading all the raw data. This will take some time…"
  foreach(artjoin, df.file)
end

calibs = CSV.read(artjoin("calibrations.csv"), DataFrame)
@rtransform!(calibs, :extrinsic = tosecond(:extrinsic), :file = artjoin(:calibration_ID))
@select!(calibs, :calibration_ID, :calibration = time2calib.(:file, :extrinsic))

df = innerjoin(df, calibs, on = "calibration_ID")
select!(df, Not("calibration_ID"))
@rtransform!(df, :duration = tosecond(:stop - :start))


@info "Tracking videos. This will take some time…"
results = joinpath("..", "results")
tracks = joinpath(results, "tracks")
mkpath(tracks)
n = nrow(df)
p = Progress(n)
# tracks = Vector{Any}(undef, n)
# Threads.@threads for rownumber in 1:n
Threads.@threads for row in eachrow(df)
  # file, start, stop, calibration = df[rownumber, [:file, :start, :stop, :calibration]]
  # track = get_track(rownumber, file, start, stop, calibration)
  track = get_track(row.rownumber, row.file, row.start, row.stop, row.calibration)
  t = range(0, row.duration, 1000)
  xy = track.(t)
  (t = t, x = first.(xy), y = last.(xy)) |> CSV.write(joinpath(tracks, string(row.rownumber, ".csv")))
  next!(p)
end

#
#
#   tracks[rownumber] = get_track(rownumber, file, start, stop, calibration)
#   next!(p)
# end
# df.track .= tracks
#
#
#
#
# ratio = retrieve(conf, "proportion_of_shortest", "ratio", Float64)
# temporalROI = round(Int, ratio*minimum(df.duration))
#
# @rtransform!(df, :cordlength = cordlength(:track, :duration, temporalROI), :curvelength = get_curvelength(:track, :duration, temporalROI))
# @transform!(df, :tortuosity = :cordlength ./ :curvelength, :speed = :curvelength / temporalROI)
#
# select(df, Not(Cols(:track, :calibration))) |> CSV.write(joinpath(results, "data.csv"))
