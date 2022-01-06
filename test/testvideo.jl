using Test
using Dates, LinearAlgebra
using Autotrack, VideoIO, CSV, QuadGK, Dierckx
using GLMakie
using LazyArtifacts

include(joinpath("..", "track", "utils.jl"))

t = 10
w = 1440
h = 1080
speed = sqrt((w/2)^2 + (h/2)^2)/t
xy = Node(Point2f0(w/2, h/2))
fig = Figure(resolution = (w, h), figure_padding = (0,0,0,0))
ax = Axis(fig[1,1], limits = (1, w, 1, h), backgroundcolor = :gray)
hidedecorations!(ax)
hidespines!(ax)
scatter!(ax, xy, color = :black, markersize = 25)
framerate = 30
θ = atan((h/2)/(w/2))

mktempdir() do path
  file = joinpath(path, "testvideo.mp4")
  record(fig, file, 1:t*framerate; framerate = framerate) do hue
    xy[] += Point2f0(speed/framerate .* reverse(sincos(θ)))
  end
  @testset "vanila" begin
    speed_hat, tortuocity = processrun(file, 0, file, t, 1, 0)
    @test isapprox(speed_hat, speed, atol = 1)
    @test isapprox(tortuocity, 1, atol = 1e-4)
  end

  file2 = joinpath(path, "testvideo_SAR.mp4")
  sar = 4//3
  VideoIO.FFMPEG.ffmpeg() do exe
    run(`$exe  -v error -i $file -c copy -bsf:v "h264_metadata=sample_aspect_ratio=$(sar.num)/$(sar.den)" $file2`)
  end

  @testset "sar" begin
    speed_hat, tortuocity = processrun(file2, 0, file2, t, 1, 0)
    speed2 = sqrt((w/2*sar)^2 + (h/2)^2)/t
    @test isapprox(speed_hat, speed2, atol = 1)
    @test isapprox(tortuocity, 1, atol = 1e-4)
  end

  @testset "calibration" begin
    calib = 10
    speed_hat, tortuocity = processrun(file2, 0, file2, t, calib, 0)
    speed2 = calib*sqrt((w/2*sar)^2 + (h/2)^2)/t
    @test isapprox(speed_hat, speed2, atol = 1calib)
    @test isapprox(tortuocity, 1, atol = 1e-4)
  end
end
