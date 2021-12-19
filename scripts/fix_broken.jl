using Revise
using Autotrack, DataFramesMeta
using LazyArtifacts, Dates
using ThreadsX, ConfParser

using VideoIO, CSV, Dierckx, StaticArrays

conf = ConfParse("configuration.ini")
parse_conf!(conf)

include("../entrypoint1/utils.jl")

function get_track(rownumber, file, start_time, stop_time, guess)
  file = joinpath(artifact"SisyphusCooperation/rawdata/videos", file)
  t₀ = get_start_time(file)
  start_time = tosecond(start_time) + t₀
  stop_time = tosecond(stop_time) + t₀
  debug = joinpath("vids", string(rownumber))
  t1, t2, spl, ar = track(file, start_time, file, stop_time; debug, guess)
  return nothing
end

function get_runs()
    runs = "runs.csv"
    df = DataFrame(CSV.File("runs.csv", types = Dict("start" => Time, "stop" => Time)))
    df.rownumber .= 1:nrow(df)
    transform!(df, [:dropoffx, :dropoffy] => ByRow((x,y) -> ismissing(x) ? nothing : tuple(x, y)) => :guess)
end

df = get_runs()

# delete all the previous videos
rm.(readdir("vids", join = true))

mkpath("vids")
# process all the runs
ThreadsX.map(irow -> get_track(irow...), eachrow(select(df, [:rownumber, :file, :start, :stop, :guess])));


################ your job ##################
# try one single run
rownumber = 10 # run number
# get the runs
df = get_runs()
# get the specific `rownumber` run 
file, start_time, stop_time, guess = df[rownumber, [:file, :start_time, :stop_time, :guess]]
# process it
get_track(rownumber, file, start_time, stop_time, guess)
# now check to see if your changes helped
