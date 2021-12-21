import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Dates, LinearAlgebra, LazyArtifacts
using Autotrack, VideoIO, CSV, DataFramesMeta, Dierckx, StaticArrays, CameraCalibrations
# using ThreadsX, 
using ConfParser
using ProgressMeter

const conf = ConfParse("configuration.ini")
parse_conf!(conf)

include("utils.jl")
include("calibrations.jl")

calibs = CSV.read(artifact"SisyphusCooperation/rawdata/csvs/calibrations.csv", DataFrame)

@rtransform!(calibs, :extrinsic = tosecond(:extrinsic), :file = joinpath(artifact"SisyphusCooperation/rawdata/videos", :calibration_ID))
@select!(calibs, :calibration_ID, :calibration = time2calib.(:file, :extrinsic))

df = CSV.read(artifact"SisyphusCooperation/rawdata/csvs/runs.csv", DataFrame, types = Dict("start" => Time, "stop" => Time))
df = innerjoin(df, calibs, on = "calibration_ID")
select!(df, Not("calibration_ID"))

# df.track = ThreadsX.map(irow -> get_track(first(irow), last(irow)...), pairs(eachrow(select(df, [:file, :start, :stop, :calibration]))));

n = nrow(df)
p = Progress(n)
tracks = Vector{Any}(undef, n)
Threads.@threads for rownumber in 1:n
    file, start, stop, calibration = df[rownumber, [:file, :start, :stop, :calibration]]
    tracks[rownumber] = get_track(rownumber, file, start, stop, calibration)
    next!(p)
end
df.track .= tracks

# df.track = tcollect(withprogress(get_track(first(irow), last(irow)...) for irow in pairs(eachrow(select(df, [:file, :start, :stop, :calibration])))); basesize = 1);


@rtransform!(df, :duration = tosecond(:stop - :start))#, :species, $"couple ID", $"with female", $"exit azimuth", :IDs, :track)

histogram(df.duration)


ratio = retrieve(conf, "proportion_of_shortest", "ratio", Float64)
temporalROI = round(Int, ratio*minimum(df.duration))

@rtransform!(df, :cordlength = cordlength(:track, :duration, temporalROI), :curvelength = get_curvelength(:track, :duration, temporalROI))
@transform!(df, :tortuosity = :cordlength ./ :curvelength, :speed = :curvelength / temporalROI)

@select!(df, Not(things))

mkpath("results")
CSV.write(joinpath("results", "data.csv"), df)
