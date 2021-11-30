# implementation
function start_time(file)
  VideoIO.FFMPEG.ffprobe() do exe
    txt = read(`$exe  -v error -show_entries format=start_time -of default=noprint_wrappers=1:nokey=1 $file`, String)
    parse(Float64, txt)
  end
end

struct Segment
  file::String
  video::VideoIO.StreamContext
  start_time::Float64
  Segment(file::String, opts...) = new(file, VideoIO.openvideo(file, opts...), start_time(file))
end


mutable struct SegmentedVideo
  segments::Vector{Segment}
  current::Int
  SegmentedVideo(files::Vector{AbstractString}, opts...) = new(Segment.(files, opts...), 1)
end

VideoIO.openvideo(files::Vector{AbstractString}, opts...) = SegmentedVideo(files, opts...)

get_current(v::SegmentedVideo, f::Symbol) = getfield(v.segments[v.current], f)

VideoIO.aspect_ratio(v::SegmentedVideo) = VideoIO.aspect_ratio(get_current(v, :video))

function VideoIO.seek(v::SegmentedVideo, t::Number)
  i = findlast(s -> s.start_time < t, v.segments)
  v.current = isnothing(i) ? 1 : i
  seek(get_current(v, :video), t)
end

function VideoIO.seek(v::SegmentedVideo, file::String, t::Number)
  v.current = findfirst(s -> s.file == file, v.segments)
  seek(get_current(v, :video), get_current(v, :start_time) + t)
end

function VideoIO.read!(v::SegmentedVideo, img)
  if eof(get_current(v, :video)) && v.current < length(v.segments)
    v.current += 1
  end
  read!(get_current(v, :video), img)
end

function VideoIO.read(v::SegmentedVideo) 
  if eof(get_current(v, :video)) && v.current < length(v.segments)
    v.current += 1
  end
  read(get_current(v, :video))
end

VideoIO.gettime(v::SegmentedVideo) = gettime(get_current(v, :video))


