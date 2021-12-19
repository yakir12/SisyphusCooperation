import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Dates, LinearAlgebra, LazyArtifacts
using Autotrack, VideoIO, CSV, DataFramesMeta, Dierckx, StaticArrays, CameraCalibrations
using ThreadsX, ConfParser

conf = ConfParse("configuration.ini")
parse_conf!(conf)

include("utils.jl")
include("calibrations.jl")

calibs = DataFrame(CSV.File(artifact"SisyphusCooperation/rawdata/csvs/calibrations.csv"))

@rtransform!(calibs, :extrinsic = tosecond(:extrinsic), :file = joinpath(artifact"SisyphusCooperation/rawdata/videos", :calibration_ID))
checker = retrieve(conf, "checker", "width", Float64)
@select!(calibs, :calibration_ID, :calibration = time2calib.(:file, :extrinsic, checker))

df = DataFrame(CSV.File(artifact"SisyphusCooperation/rawdata/csvs/runs.csv", types = Dict("start" => Time, "stop" => Time)))
df = innerjoin(df, calibs, on = "calibration_ID")
select!(df, Not("calibration_ID"))

debug = retrieve(conf, "videotrack", "debug", Bool)
df.track = ThreadsX.map(irow -> get_track(first(irow), last(irow)..., debug), pairs(eachrow(select(df, [:file, :start, :stop, :calibration]))));
@rselect!(df, :duration = tosecond(:stop - :start), :species, $"couple ID", $"with female", $"exit azimuth", :IDs, :track)

@rtransform!(df, :cordlength = norm(:track(:duration) - :track(0)), :curvelength = get_curvelength(:duration, :track))
@transform!(df, :tortuosity = :cordlength ./ :curvelength, :speed = :curvelength ./ :duration)

mkpath("results")
CSV.write(joinpath("results", "data.csv"), df)
