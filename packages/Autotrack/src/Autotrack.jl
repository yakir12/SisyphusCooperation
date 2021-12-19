module Autotrack

using Dates, LinearAlgebra, Statistics
using VideoIO, ColorVectorSpace, Dierckx, ImageTransformations, ImageDraw, StaticArrays, PaddedViews, OffsetArrays, ImageFiltering, ColorTypes
SV = SVector{2, Float64}

export track

# include("video.jl")

const window_radius = 4
const nframes = 25 # data points
const σ = 0.85
const smoothing_factor = 200
# sz = (108, 144)
const scale = 10

w = CartesianIndex(window_radius, window_radius)
const window = -w:w

# _parse_time(::Nothing, T) = 0.0
# _parse_time(x, T) = Millisecond(T(parse(Int, x)))/Millisecond(Second(1))
# _parse_time(xT) = _parse_time(xT...)
#
# function _get_seconds(txt)
#   m = match(r"(?:(\d+):)*(\d+):(\d+)(?:,(\d+))*", txt)
#   sum(_parse_time, zip(m.captures, (Hour, Minute, Second, Millisecond)))
# end

function seekread!(img, vid, t)
  seek(vid, t)
  read!(vid, img)
end

# function get_times(start::Time, stop::Time)
#   t1 = _get_seconds(start)
#   t2 = _get_seconds(stop)
#   range(t1, t2, length = nframes)
# end

function get_next(guess, img, bkgd)
  centered_img = OffsetArrays.centered(img, Tuple(guess))
  centered_bkgd = OffsetArrays.centered(bkgd, Tuple(guess))
  x = centered_bkgd[window] .- centered_img[window]
  imfilter!(x, x, Kernel.DoG(σ))
  _, i = findmax(x)
  guess + window[i]
end

function get_imgs(vid, ts)
  img = read(vid)
  # t₀ = gettime(vid)
  h, w = size(img)
  width_ind = 1:scale:w
  height_ind = 1:scale:h
  sz = (length(height_ind), length(width_ind))

  unpadded_imgs = [similar(img, sz) for _ in 1:nframes]
  for (i, t) in enumerate(ts)
    seekread!(img, vid, t)
    # seekread!(img, vid, t + t₀)
    unpadded_imgs[i] .= img[height_ind, width_ind]
  end

  height, width = sz
  padded_axes = (1-window_radius:height+window_radius, 1-window_radius:width+window_radius)
  imgs = PaddedView.(zero(eltype(img)), unpadded_imgs, Ref(padded_axes))
  bkgd = PaddedView(zero(eltype(img)), mean(unpadded_imgs), padded_axes)

  return sz, imgs, bkgd
end

function get_spline(imgs, bkgd, ts, guess)
  coords = accumulate((guess, img) -> get_next(guess, img, bkgd), imgs, init = guess)
  ParametricSpline(ts, hcat(SV.(Tuple.(coords))...); s = smoothing_factor, k = 2)
end

function track(start_file, start_time, stop_file, stop_time; debug = nothing, guess = nothing)

  if start_file == stop_file
    vid = VideoIO.openvideo(start_file, target_format=VideoIO.AV_PIX_FMT_GRAY8)
    ts = range(start_time, stop_time, length = nframes)
    sz, imgs, bkgd = get_imgs(vid, ts)
    spl = get_spline(imgs, bkgd, ts, isnothing(guess) ? CartesianIndex(sz .÷ 2) : CartesianIndex(guess .÷ scale))
  else
    @error "waaaat"
  end

  ar = VideoIO.aspect_ratio(vid)
  if !isnothing(debug)
    save(debug, ts, imgs, spl, ar)
  end

  return ts[1], ts[end], spl, scale*[1, ar]
end

# function get_data(videofile, start, stop)
#
#   vid = VideoIO.openvideo(videofile, target_format=VideoIO.AV_PIX_FMT_GRAY8)
#   ts = get_times(start, stop)
#   sz, imgs, bkgd = get_imgs(vid, ts)
#   spl = get_spline(sz, imgs, bkgd, ts)
#
#   return ts, imgs, spl, VideoIO.aspect_ratio(vid)
# end

function save(result_file, ts, imgs, spl, aspect_ratio)
  # ar = SV(1, aspect_ratio)
  # txy = (NamedTuple{(:t, :x, :y)}((t, ar .* spl(t)...)) for t in ts[1] : 1/10 : ts[end])
  # # txy = (NamedTuple{(:t, :x, :y)}((t, spl(t)...)) for t in ts[1] : 1/10 : ts[end])
  # CSV.write("$result_file.csv", txy)

  encoder_options = (color_range=2, crf=23, preset="medium")
  time = 2
  framerate = round(Int, length(ts)/time)
  open_video_out("$result_file.mp4", parent(imgs[1]), framerate=framerate, encoder_options=encoder_options) do writer
    for (i, t) in enumerate(ts)
      path = Path([CartesianIndex(Tuple(round.(Int, spl(i)))) for i in ts[1] : 1/10 : t])
      img = parent(imgs[i])
      draw!(img, path)
      write(writer, img)
    end
  end

end

# function process_track(video_file, start, stop, result_file)
#   data = get_data(video_file, start, stop)
#   save(result_file, data...)
# end
#
# function _process_tracks(rows, f, video_dir, result_dir)
#   @showprogress for (row, (file, start, stop)) in enumerate(f)
#     process_track(joinpath(video_dir, file), start, stop, joinpath(result_dir, string(row)))
#   end
# end
#
# function process_tracks(csvfile; video_dir = dirname(csvfile), result_dir = dirname(csvfile))
#   f = CSV.File(csvfile)
#   rows = 1:length(f)
#   _process_tracks(rows, f, video_dir, result_dir)
# end
#
# function process_tracks(csvfile, row::Int; video_dir = dirname(csvfile), result_dir = dirname(csvfile))
#   f = CSV.File(csvfile)
#   file, start, stop = f[row]
#   process_track(joinpath(video_dir, file), start, stop, joinpath(result_dir, string(row)))
# end
#
# function process_tracks(csvfile, rows::AbstractVector{Int}; video_dir = dirname(csvfile), result_dir = dirname(csvfile))
#   f = CSV.File(csvfile)
#   _process_tracks(rows, f, video_dir, result_dir)
# end

end
