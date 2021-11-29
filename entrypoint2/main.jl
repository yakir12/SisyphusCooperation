import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Dates, LinearAlgebra, LazyArtifacts
using CSV, DataFramesMeta, GLMakie, AlgebraOfGraphics

n = 5
df = DataFrame(g = 1:n, xy = [[Point2(rand(2)) for _ in 1:2] for _ in 1:n])
fig = draw(mapping(df.xy, layout=df.g => nonnumeric) * visual(Lines))

df = DataFrame(CSV.File(artifact"SisyphusCooperation/processeddata/csvs/data.csv"))
g = groupby(df, ["species", "couple ID", "with female"])
@transform!(g, :run = 1:length(:speed))
g = groupby(df, ["species", "couple ID", "run"])
x = @combine(g, :line = Ref(Point2.($"with female", :speed)))

mkpath("results")

for (k, x1) in pairs(groupby(x,:species))
    xy = mapping(x1.line, layout = x1."couple ID", color = x1.run)
    layers = visual(Lines)
    f = draw(layers * xy)
    save(joinpath("results", string(k..., " speed per couple.png")), f)
end



axis = (width = 225, height = 225)
for (k, g) in pairs(groupby(df, :species)), (y, datalimits) in zip((:speed, :tortuosity), ((0, Inf), (0, 1)))
    toplot = data(g) * visual(Violin; datalimits) * mapping("with female", y, col = "couple ID", color="with female") 
    f = draw(toplot; axis)
    save(joinpath("results", string(k..., " ", y, ".png")), f)
end
