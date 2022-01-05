function time2calib(video, extrinsic)
  mktempdir() do path
    extrinsic = extract(video, extrinsic, path)
    checker = retrieve(conf, "checker", "width", Float64)
    buildcalibration(checker, extrinsic)
  end
end

function extract(video, ss, path)
  to = joinpath(path, "extrinsic.png")
  VideoIO.FFMPEG.ffmpeg_exe(`-loglevel 8 -ss $ss -i $video -vf format=gray,yadif=1,scale=sar"*"iw:ih -pix_fmt gray -vframes 1 $to`)
  to
end


# function time2calib(video, intrinsic_start, intrinsic_stop, extrinsic, checker)
#   mktempdir() do path
#     # intrinsic = extract(video, intrinsic_start, intrinsic_stop, path)
#     extrinsic = extract(video, extrinsic, path)
#     # buildcalibration(checker, extrinsic, intrinsic)
#     buildcalibration(checker, extrinsic)
#   end
# end
#
# function extract(video, ss, t2, path)
#   t = t2 - ss
#   r = 25/t
#   files = joinpath(path, "intrinsic%03d.png")
#   VideoIO.FFMPEG.ffmpeg_exe(`-loglevel 8 -ss $ss -i $video -t $t -r $r -vf format=gray,yadif=1,scale=sar"*"iw:ih -pix_fmt gray $files`)
#   readdir(path, join = true)
# end
#
# function extract(video, ss, path)
#   to = joinpath(path, "extrinsic.png")
#   VideoIO.FFMPEG.ffmpeg_exe(`-loglevel 8 -ss $ss -i $video -vf format=gray,yadif=1,scale=sar"*"iw:ih -pix_fmt gray -vframes 1 $to`)
#   to
# end
#
#
