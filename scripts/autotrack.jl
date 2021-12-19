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

runs = "runs.csv"

bad = CSV.read("broken.csv", DataFrame, select = [1])
rename!(bad, "#" => "rownumber")
df = DataFrame(CSV.File("runs.csv", types = Dict("start" => Time, "stop" => Time)))
df.rownumber .= 1:nrow(df)
transform!(df, [:dropoffx, :dropoffy] => ByRow((x,y) -> ismissing(x) ? missing : tuple(x, y)) => :guess)
df = innerjoin(df, bad, on = "rownumber")
rm.(readdir("vids", join = true))


fixed1 = [2, 57, 83, 87, 133, 225, 228, 230, 231, 236, 238, 240, 245, 251, 287, 300, 399, 402, 403] # fixed by subtracting 1 from start time
fixed2 = [81, 82, 97, 187, 193, 239, 246, 277, 357, 360, 361, 362, 365, 366, 367, 368, 372, 376, 378, 379, 381, 383, 384, 385, 386, 391, 394, 395, 397, 398, 400, 404] # fixed by subtracting 2 from start time
fixed3 = [108, 196, 242, 244, 254, 390, 380, 382, 392, 393, 396] # fixed by subtracting 3 from start time
fixed4 = [1, 51, 79, 252] # fixed by subtracting 4 from start time
fixed5 = [227, 250] # fixed by subtracting 5 from start time

df = @rsubset(df, :rownumber ∉ [fixed1; fixed2; fixed3; fixed4; fixed5])

df = @rsubset(df, :rownumber ∈ 317:356)

ThreadsX.map(irow -> get_track(irow...), eachrow(select(df, [:rownumber, :file, :start, :stop])));


# cp(artifact"SisyphusCooperation/rawdata/csvs/runs.csv", "runs.csv", force = true)
# Base.Filesystem.chmod("runs.csv", 0o777)
# df = DataFrame(CSV.File("runs.csv", types = Dict("start" => Time, "stop" => Time)))
# df.rownumber .= 1:nrow(df)
# fun(x, n) = x == "20210709_A.MTS" ? n : missing
# @rtransform!(df, :dropoffx = fun(:file, 516), :dropoffy = fun(:file, 835))
# @rtransform!(df, :start = 
#              :rownumber ∈ fixed1 ? :start - Second(1) : 
#              :rownumber ∈ fixed2 ? :start - Second(2) : 
#              :rownumber ∈ fixed3 ? :start - Second(3) : 
#              :rownumber ∈ fixed4 ? :start - Second(4) : 
#              :rownumber ∈ fixed5 ? :start - Second(5) : 
#              :start)
# CSV.write("runs.csv", df)

