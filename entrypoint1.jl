using Dates, LinearAlgebra, LazyArtifacts
using Autotrack, VideoIO, CSV, DataFramesMeta, Dierckx, StaticArrays, CameraCalibrations
using ThreadsX

#
debug = false # set to true if you want to save video snippets of the tracked beetles. This helps assesing the quality of the auto-tracking.
checker = 4.1 # in cm

include("utils.jl")
include("calibrations.jl")
#
calibs = DataFrame(CSV.File(artifact"SisyphusCooperation/rawdata/csvs/calibrations.csv"))

@rtransform!(calibs, :extrinsic = tosecond(:extrinsic), :file = joinpath(artifact"SisyphusCooperation/rawdata/videos", :calibration_ID))
@select!(calibs, :calibration_ID, :calibration = time2calib.(:file, :extrinsic, checker))

df = DataFrame(CSV.File(artifact"SisyphusCooperation/rawdata/csvs/runs.csv", types = Dict("start" => Time, "stop" => Time)))
df = innerjoin(df, calibs, on = "calibration_ID")
select!(df, Not("calibration_ID"))

df.track = ThreadsX.map((i, row) -> get_track(i, row...), pairs(eachrow(select(df, [:file, :start, :stop, :calibration]))));
@rselect!(df, :duration = tosecond(:stop - :start), :species, $"couple ID", $"with female", $"exit azimuth", :IDs, :track)

@rtransform!(df, :cordlength = norm(:track(:duration) - :track(0)), :curvelength = get_curvelength(:duration, :track))
@transform!(df, :tortuosity = :cordlength ./ :curvelength, :speed = :curvelength ./ :duration)

mkpath("results")
CSV.write(joinpath("results", "data.csv"), df)

using GLMakie
fig = Figure()
ax = Axis(fig[1,1], aspect = DataAspect())
@eachrow df begin
  xy = :track.(range(0, :duration, 25))
  lines!(ax, xy)
end

