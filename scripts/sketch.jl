
using GLMakie
fig = Figure()
ax = Axis(fig[1,1], aspect = DataAspect())
@eachrow df begin
  xy = :track.(range(0, :duration, 25))
  lines!(ax, xy)
end


transform!(calibs, ["intrinsic start", "intrinsic stop", "extrinsic"] .=> ByRow(tosecond) .=> ["intrinsic start", "intrinsic stop", "extrinsic"],
           "calibration ID" => ByRow(x -> joinpath("..", "main", "tmp", x)) => "file name")
#
# calibs = calibs[1:1, :]
#
calibs.calibration = @showprogress map(eachrow(calibs)) do row
  time2calib(row."file name", row."intrinsic start", row."intrinsic stop", row.extrinsic, checker)
end;
select!(calibs, ["calibration ID", "calibration"])
#
file = "runs3.csv"
df = CSV.read(file, types = Dict("start time" => Time, "stop time" => Time), DataFrame)
df = innerjoin(df, calibs, on = "calibration ID")
select!(df, Not("calibration ID"))
#

include("utils.jl")
using ThreadsX
df.track = ThreadsX.map(get_track, eachrow(df));
#

using GLMakie
fig = Figure()
ax = Axis(fig[1,1], aspect = DataAspect())
for track in df.track
  lines!(ax, Point{2, Float64}.(vec.(track.coords)))
end








file = "runs3.csv"
df = CSV.read(file, DataFrame, types = Dict("start" => String, "stop" => String))
while any(<(12) ∘ length, df.start)
  @rtransform!(df, :start = length(:start) < 12 ? string(:start, "0") : :start)
end
while any(<(12) ∘ length, df.stop)
  @rtransform!(df, :stop = length(:stop) < 12 ? string(:stop, "0") : :stop)
end
CSV.write("runs4.csv", df)




x = CSV.read("video2calib.csv", DataFrame)

df2 = innerjoin(df, x, on = "start file" => "video")

CSV.write("runs3.csv", df2)


# calibs.calibration = @showprogress map(eachrow(calibs)) do row
#   time2calib(row."file name", row."intrinsic start", row."intrinsic stop", row.extrinsic, checker)
# end;


#
df = mktemp() do file, _
  # run(`aws s3 cp s3://dackelab/claudiatocco/runs.csv $file`)
  file = "runs2.csv"
  CSV.read(file, dateformat = "HH:MM:SS,sss", types = Dict("start time" => Time, "stop time" => Time), DataFrame)
end




# df = df[1:3, :]
# transform!(df, ["start file", "start time", "stop file", "stop time"] => ByRow(processrun) => [:speed, :tortuosity])

# using ProgressMeter
# p = Progress(nrow(df))
# df.speed .= 0.0
# df.tortuosity .= 0.0
# Threads.@threads for row in eachrow(df)
#   row.speed, row.tortuosity = processrun(row["start file"], row["start time"], row["stop file"], row["stop time"])
#   next!(p)
# end

using ThreadsX
st = ThreadsX.map(processrun, eachrow(df))
df.speed = first.(st)
df.tortuosity = last.(st)

using AlgebraOfGraphics, GLMakie

axis = (width = 225, height = 225)
for (k, g) in pairs(groupby(df, :species)), (y, datalimits) in zip((:speed, :tortuosity), ((0, Inf), (0, 1)))
  toplot = data(g) * visual(Violin; datalimits) * mapping("with female", y, col = "couple ID", color="with female") 
  f = draw(toplot; axis)
  save(joinpath("results", string(k..., " ", y, ".png")), f)
end


# TODO
# add the calibration to this process
# fix the processrun function so that the path to the fil eis globally correct, so that the tests can run (test then)
# add date and times for each run

# check that the tracking worked in each and everyone of these
# check to see what the affect of repeated subsequent runs has on speed and tortuosity. Might be big, in which case we might want to run this comparison with just the first 2 runs (per group) or some such.

# make sure parallelization is sanctioned by others

