function get_start_time(file)
  txt = read(`$(VideoIO.FFMPEG.ffprobe()) -v error -show_entries format=start_time -of default=noprint_wrappers=1:nokey=1 $file`, String)
  parse(Float64, txt) # in float seconds
end

# VideoIO.FFMPEG.ffprobe() do exe
#   txt = read(`$exe  -v error -show_entries format=start_time -of default=noprint_wrappers=1:nokey=1 $file`, String)
#   parse(Float64, txt) # in float seconds
# end
# end

tosecond(x::Nanosecond) = Dates.tons(x)*1e-9
tosecond(x::Time) = tosecond(x - Time(0))

artifact_downloaded(x) = artifact_exists(artifact_hash(first(splitext(x)), "Artifacts.toml"))
artjoin(x) = @artifact_str(joinpath(first(splitext(x)), x)) 

function get_track(rownumber, file, start_time, stop_time, calibration, guess)

  file = artjoin(file)
  t₀ = get_start_time(file)
  start_time = tosecond(start_time) + t₀
  stop_time = tosecond(stop_time) + t₀

  debug = retrieve(conf, "videotrack", "debug", Bool) ? joinpath(pwd(), string(rownumber)) : nothing
  t1, t2, spl, ar = track(file, start_time, file, stop_time; debug , guess)

  c = calibrate(calibration, SVector{2, Float64}(ar .* spl(t1)))
  fun(t) = SVector{2, Float64}(calibrate(calibration, SVector{2, Float64}(ar .* spl(t + t1))) .- c)

  return fun

end

function cordlength(track, duration, temporalROI)
  Δ = duration - temporalROI
  ts = Δ/2 .+ [0, temporalROI]
  norm(diff(track.(ts)))
end

function get_curvelength(track, duration, temporalROI)
  Δ = duration - temporalROI
  t1, t2 = Δ/2 .+ [0, temporalROI]
  ts = range(t1, t2, length = 1000)
  sp0 = reduce(ts, init = (s = 0.0, p0 = track(t1))) do sp0, t
    p1 = track(t)
    (s = sp0.s + norm(p1 - sp0.p0), p0 = p1)
  end
  return sp0.s
end


#   ts = range(t1, t2, length = 101)[1:end-1]
#
#   #   # dfun(t) = ForwardDiff.derivative(fun, t)
#   #   # curvelength, _ = quadgk(t -> norm ∘ dfun, t1, t2)
#   #
#   cordlength = norm(fun(t2) - fun(t1))
#
#   ts = range(t1, t2, length = 1000)
#   sp0 = reduce(ts, init = (s = 0.0, p0 = fun(t1))) do sp0, t
#     p1 = fun(t)
#     (s = sp0.s + norm(p1 - sp0.p0), p0 = p1)
#   end
#   curvelength = clamp(sp0.s, cordlength, Inf)
#
#   (rawcoords = funraw.(ts), coords = fun.(ts), speed = curvelength/(t2 - t1), tortuosity = cordlength/curvelength)
#
#   # curvelength, _ = quadgk(t -> norm(ar .* derivative(spl, t)), t1, t2)
#
#   # (speed = curvelength/(t2 - t1), tortuosity = norm(ar .* (spl(t2) - spl(t1)))/curvelength)
#
# end
#
# get_track(row) = get_track(row."start file", row."start time", row."stop file", row."stop time", row.calibration)











# # edit a csv file so it fits the new format
# df = CSV.read("calibrations.csv", DataFrame, dateformat = "MM:SS,sss")
# dropmissing!(df)
# CSV.write("calibrations2.csv", df)
#
#
# # edit a csv file so it fits the new format
# df = CSV.read("runs.csv", DataFrame)
# transform!(df, :start => ByRow(x -> string("00:", strip(x))) => :start,
#            :stop => ByRow(x -> string("00:", strip(x))) => :stop
#           )
# rename!(df, "file name" => "start file")
# rename!(df, "start" => "start time")
# rename!(df, "stop" => "stop time")
# rename!(df, "replica" => "couple ID")
# rename!(df, "role" => "with female")
# rename!(df, "exit" => "exit azimuth")
# rename!(df, "Ids" => "IDs")
# transform!(df, "with female" => ByRow(x -> x == "c") => "with female")
# df[!, "stop file"] .= df[!,"start file"]
# select!(df, ["start file", "start time", "stop file", "stop time", "species", "couple ID", "with female", "exit azimuth", "IDs"])
# CSV.write("runs2.csv", df)
#
# calculate the median of all the speeds
# m = median(norm(ar .* derivative(spl, t)) for t in range(t1, t2, length = 100))
