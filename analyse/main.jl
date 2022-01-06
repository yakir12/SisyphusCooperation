import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Dates, LinearAlgebra, LazyArtifacts, Statistics
using CSV, DataFramesMeta, GLMakie, AlgebraOfGraphics
using ConfParser

const conf = ConfParse("configuration.ini")
parse_conf!(conf)

include("utils.jl")

df = CSV.read(artifact"runs/runs.csv", DataFrame; types = Dict("with female" => Bool), select = ["species", "couple ID", "with female", "exit azimuth", "IDs", "rownumber"])
tracks = DataFrame((rownumber = parse(Int, first(splitext(basename(file)))), xyt = CSV.File(file)) for file in readdir(artifact"tracks/tracks", join = true)) 
df = innerjoin(df, tracks, on = :rownumber)
select!(df, Not(:rownumber))
@rtransform!(df, :cordlength = cordlength(:xyt), :curvelength = curvelength(:xyt), :duration = duration(:xyt))
@transform!(df, :tortuosity = :cordlength ./ :curvelength, :speed = :curvelength ./ :duration)

results = joinpath("..", "results")
select(df, Not(Cols(:xyt))) |> CSV.write(joinpath(results, "data.csv"))

# Statistics
using MixedModels

# Plotting

fig = Figure()
ax = Axis(fig[1,1], aspect = DataAspect(), xlabel = "X (cm)", ylabel = "Y (cm)")
radius = retrieve(conf, "arena", "radius", Float64)
for xyt in df.xyt
  i = findfirst(row -> sqrt(row.x^2 + row.y^2) ≥ radius, xyt)
  if isnothing(i)
    i = length(xyt)
  end
  lines!(ax, xyt.x[1:i], xyt.y[1:i])
end
lines!(ax, Circle(Point2f(0, 0), radius), color = :black)
hidespines!(ax)
save(joinpath(results, "tracks.png"), fig)


g = groupby(df, ["species", "couple ID", "with female"])
@transform!(g, :run = 1:length(:speed))
g = groupby(df, ["species", "couple ID", "run"])
for modality in (:speed, :tortuosity, :cordlength, :curvelength, :duration)
  x = @combine(g, :line = Ref(Point2{Float64}.($"with female", $"$modality")))
  axis = (; xticks = (0:1, ["solo", "pair"]), ylabel = "$modality")
  for (k, x1) in pairs(groupby(x,:species))
    xy = mapping(x1.line, layout = x1."couple ID")
    layers = visual(Lines)
    f = draw(layers * xy; axis)
    save(joinpath(results, string(k..., " $modality.png")), f)
  end
end

# accuracy as vector length
degree2vector(α) = [reverse(sincosd(α))...]
g = groupby(df, ["species", "couple ID", "with female"])
x = @combine(g, :accuracy = norm(mean(degree2vector.($"exit azimuth"))))
CSV.write(joinpath(results, "accuracy.csv"), x)
g = groupby(x, ["species", "couple ID"])
x = @combine(g, :line = Ref(Point2{Float64}.($"with female", :accuracy)))
for (k, x1) in pairs(groupby(x, :species))
  local fig
  fig = draw(mapping(x1.line, layout=x1."couple ID") * visual(Lines), axis = (; ylabel = "vector length", xticklabelrotation = π/2, xticks = ([0, 1], ["solo", "couple"])))
  save(joinpath(results, string(k..., " accuracy.png")), fig)
end

