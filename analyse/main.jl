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

ys = [:cordlength, :curvelength, :speed, :duration, :tortuosity]
units = Dict(Pair.(string.(ys), ["(cm)", "(cm)", "(cm/sec)", "(sec)", ""]))
data = @chain df begin
    select(:species, "with female", "couple ID", ys...)
    rename(Dict("with female" => "status", "couple ID" => "ID"))
    @rtransform(:status = :status ? "duo" : "solo")
    groupby(:ID)
    @transform!(:iteration = 1:length(:ID))
end

function fun(ID, status, value)
    tbl = DataFrame(ID = ID, status = status, value = value)
    @chain tbl begin
        groupby(:ID)
        @combine(:t = [solo - duo for solo in :value[:status .== "solo"] for duo in :value[:status .== "duo"]])
        _.t
    end
end
h = @chain data begin
    stack(ys)
    groupby([:species, :variable])
    @combine(:solo = Ref(:value[:status .== "solo"]), 
             :duo = Ref(:value[:status .== "duo"]),
             :Δ = Ref(fun(:ID, :status, :value)))
end

function plotΔ(f, solo, duo, Δ, xlabel = "")
    m, M = extrema([solo; duo])
    μ = M - m > 1 ? round(Int, (M + m)/2) : round((M + m)/2, digits = 1)
    # μ = round(Int, middle([solo; duo]))
    # μ = round(middle([solo; duo]), digits = 1)
    ax1 = Axis(f; xlabel)
    # boxplot!(ax1, zeros(length(Δ)), Δ, orientation = :horizontal, show_outliers = false, show_median = false, color = :grey)
    boxplot!(ax1, zeros(length(Δ)), Δ .+ μ, orientation = :horizontal, show_outliers = false, show_notch = true, show_median = true, whiskerwidth = :match, color = :grey)
    hideydecorations!(ax1)
    ax1.xtickformat = xs -> fmtrfunc.(round.(xs .- μ, digits = 2))
    ax1
end
function plotsoloduo(f, solo, duo)
    ax2 = Axis(f)
    hist!(ax2, solo, label = "solo")
    hist!(ax2, duo, label = "duo")
    ax2
end
#
w = 200
fig = Figure(resolution = (2w*length(ys), 3w))
gs = groupby(h, :species)
for (col, (k, g)) in enumerate(pairs(groupby(gs[1], :variable)))
    fig[1,col] = plotΔ(fig, g.solo[], g.duo[], g.Δ[])
    fig[2,col] = plotsoloduo(fig, g.solo[], g.duo[])
end
for (col, (k, g)) in enumerate(pairs(groupby(gs[2], :variable)))
    fig[3,col] = plotsoloduo(fig, g.solo[], g.duo[])
    fig[4,col] = plotΔ(fig, g.solo[], g.duo[], g.Δ[], string(k..., " ", units[k...]))
end
for i in [1,4]
    rowsize!(fig.layout, i, Relative(0.1))
end
for i in [1, 4]
    axs = contents(fig[i,:])
    for ax in axs
        # ax.xtrimspine = true
        if i == 1
            ax.bottomspinevisible = false
        else
            ax.topspinevisible = false
        end
        ax.rightspinevisible = false
        ax.leftspinevisible = false
        ax.xgridvisible = false
        ax.ygridvisible = false
    end
end
foreach(ax -> (ax.xaxisposition = :top), contents(fig[1,:]))
for col in 1:5
    linkxaxes!(contents(fig[:, col])...)
end
linkyaxes!(contents(fig[2:3, :])...)
hidexdecorations!.(contents(fig[2, :]), grid = false)
hidexdecorations!.(contents(fig[1, :]), label = true, ticklabels = false, ticks = false, grid = false, minorgrid = false, minorticks = false)
hideydecorations!.(contents(fig[2:3, 2:end]), grid = false)
foreach(ax -> (ax.ylabel = "Frequency (runs)"), contents(fig[2:3,1]))
Label(fig[1:2, 6], "fasciculatus", rotation = -π/2)
Label(fig[3:4, 6], "schaefferi", rotation = -π/2)
axislegend(contents(fig[2,1])[], position = :lt)


































using Formatting
fmtrfunc = generate_formatter( "%g" )
function plotdis(f, solo, duo, Δ)
    μ = round(Int, middle([solo; duo]))
    ax1 = Axis(f)
    boxplot!(ax1, zeros(length(Δ)), Δ .+ μ, orientation = :horizontal, show_outliers = false, show_median = false, color = :grey)
    hideydecorations!(ax1)
    ax1.xtickformat = xs -> fmtrfunc.(round.(xs .- μ, digits = 2))
    ax2 = Axis(f)
    hist!(ax2, solo, label = "solo")
    hist!(ax2, duo, label = "duo")
    return ax1, ax2
end

w = 400
fig = Figure(resolution = (w*length(ys), 2w))
for (row, (species, g)) in enumerate(pairs(groupby(data, :species))), (col, y) in enumerate(ys)
    solo = @subset(g, :status .== "solo")[!, y]
    duo = @subset(g, :status .== "duo")[!, y]
    Δ = Float64[]
    for gg in groupby(g, :ID)
        sol = @subset(gg, :status .== "solo")[!, y]
        du = @subset(gg, :status .== "duo")[!, y]
        for s in sol, d in du
            push!(Δ, s - d)
        end
    end
    fig[row, col + 1] = plotdis(fig, solo, duo, Δ)
end
linkyaxes!([contents(axs)[2] for axs in contents(fig[:,:])]...)
for col in eachindex(ys)
    linkxaxes!(reduce(vcat, contents(axs) for axs in contents(fig[:, col + 1]))...)
end

for (row, (species, _)) in enumerate(pairs(groupby(data, :species)))
    Label(fig[row, 1], string(species ...), rotation = π/2)
end
for (col, (y, yu)) in enumerate(zip(ys, ysunits))
    Label(fig[3, col + 1], "$y $yu")
end




h = @chain data begin
    groupby([:species, :status, :ID])
    combine(ys .=> mean .=> ys)
    sort([:species, :ID, :status])
    groupby([:species, :ID])
    combine(ys .=> only ∘ diff .=> ys)
end

function subtract_status(s, v)
    solo = findall(==("solo"), s)
    duo = findall(==("couple"), s)
    [xi - yi for xi in v[solo] for yi in v[duo]]
end
fig = Figure()
for (col, (y, yu)) in enumerate(zip(ys, ysunits))
    for (row, g) in enumerate(groupby(data, :species))
        ax = Axis(fig[row+2, col], xlabel = "$y $yu", ylabel = "Frequency (runs)", aspect = 1)
        for (k, g) in pairs(groupby(g, :status))
            GLMakie.hist!(ax, g[!, y]; label = string(k...))
        end
    end
end
h = @chain data begin
    sort([:species, :ID, :status])
    groupby([:species, :ID])
    @aside for (col, (y, yu)) in enumerate(zip(ys, ysunits))
        @chain _ begin
            combine(_, [:status, y] => subtract_status => y)
            for (row, g) in enumerate(groupby(_, :species))
                ax = Axis(fig[row, col], xlabel = "$y $yu", ylabel = "Difference (solo - duo)")
                GLMakie.boxplot!(ax, ones(nrow(g)), g[!, y], orientation = :horizontal, show_outliers = false, show_median = false)
            end
        end
    end
end


fig = Figure()
@chain df begin
    sort([:species, :ID, :status])
    groupby([:species, :ID])
    @aside for (col, (y, yu)) in enumerate(zip(ys, ysunits))
        @chain _ begin
            combine(_, [:status, y] => subtract_status => y)
            for (row, g) in enumerate(groupby(_, :species))
                ax = Axis(fig[row, col], xlabel = "$y $yu", ylabel = "Difference (solo - duo)")
                GLMakie.boxplot!(ax, ones(nrow(g)), g[!, y], orientation = :horizontal, show_outliers = false, show_median = false)
            end
        end
    end
end


n = 1000
μ = 10
x1 = μ .+ randn(n)
x2 = μ .+ randn(n) .+ rand()
Δ = x1 .- x2
fig = Figure()
fig[1,1] = plotdis(fig, x1, x2, Δ)



fig = Figure()
for (col, (y, yu)) in enumerate(zip(ys, ysunits))
    for (row, g) in enumerate(groupby(data, :species))
        ax = Axis(fig[row, col], xlabel = "$y $yu", ylabel = "Frequency (runs)", aspect = 1)
        for (k, g) in pairs(groupby(g, :status))
            GLMakie.hist!(ax, g[!, y]; label = string(k...))
        end
    end
end
axs = contents(fig[:,:])
linkyaxes!(axs...)
axislegend(axs[end])
for i in 1:2
    axs = contents(fig[i,:])
    foreach(ax -> hideydecorations!(ax, grid = false), axs[2:end])
end





w = 400
fig = Figure(resolution = (w*length(ys), 2w))
for (i, (y, yu)) in enumerate(zip(ys, ysunits))
    plt = AlgebraOfGraphics.data(data) * visual(Violin, datalimits = extrema) * mapping(:status, y => string(y, " ", yu), color = :species, side = :species)
    ax = Axis(fig[1, i], aspect = 1)
    draw!(ax, plt)
    ax = Axis(fig[2, i], xlabel = "$y $yu", ylabel = "Frequency (couples)", aspect = 1)
    for (k, g) in pairs(groupby(h, :species))
        GLMakie.hist!(ax, g[!, y]; label = string(k...))
    end
end
axs = contents(fig[2,:])
linkyaxes!(axs...)
foreach(ax -> hideydecorations!(ax, grid = false), axs[2:end])
axs = contents(fig[2,:])
axislegend(axs[end])

# combine(groupby(data, [:species, :status]), ys .=> mean .=> ys)








# using MixedModels, CategoricalArrays, Chain, HypothesisTests, DataWrangler
# using MixedModels:term
#
# using BoxCoxTrans, UnicodePlots
# x = BoxCoxTrans.transform(data.speed)
# x = data.speed
# μ = mean(x)
# σ = std(x, mean = μ)
# pvalue(ExactOneSampleKSTest(x, Normal(μ, σ)))
# UnicodePlots.histogram(x)
# data.speed .= x
#
# m1 = fit(MixedModel, @formula(speed ~ 1 + status*species + (1|ID)), data)
# m2 = fit(MixedModel, @formula(speed ~ 1 + status + species + (1|ID)), data)
# MixedModels.likelihoodratiotest(m1, m2)
# m3 = fit(MixedModel, @formula(speed ~ 1 + status + (1|ID)), data)
# MixedModels.likelihoodratiotest(m2, m3)
# fixef(m3)
# # m4 = fit(MixedModel, @formula(speed ~ 1 + (1|ID)), data)
# # MixedModels.likelihoodratiotest(m3, m4)
#
# function subtract_status(s, v)
#     d = NamedTuple{Tuple(Symbol.(s))}(v)
#     d.solo - d.couple
# end
#
#             # combine(:speed_mean => only ∘ diff 
#
# draw(AlgebraOfGraphics.data(y) * mapping(:speed, color = :species) * visual(Hist))
#
# combine([:status, :speed_mean] => subtract_status => :Δv,
#         [:status, :tortuosity_mean] => subtract_status => :Δt)
#
# ax1 = Axis(fig[1,1], xlabel = "Speed difference (cm/sec)", ylabel = "Frequency (couples)")
# ax2 = Axis(fig[1,2], xlabel = "Tortuosity difference")
# y = @chain data begin
#     # sort([:species, :ID, :status])
#     groupby([:species, :status, :ID])
#     combine([:speed, :tortuosity] .=> mean)
#     groupby([:species, :ID])
#     combine([:status, :speed_mean] => subtract_status => :Δv,
#             [:status, :tortuosity_mean] => subtract_status => :Δt)
#     @aside @chain _ begin 
#         for (k, g) in pairs(groupby(_, :species))
#             GLMakie.hist!(ax1, g.Δv; label = string(k...))
#             GLMakie.hist!(ax2, g.Δt; label = string(k...))
#         end
#     end
#     groupby(:species)
#     combine(:Δv => mean)
# end
#
# combine(groupby(data, [:species, :status]), :speed => mean)
#
# # newx = DataFrame((speed = 0.0, status, ID) for ID in ("a", "b") for status in ("couple", "solo"))
# # transform!(newx, [:status, :ID] .=> categorical .=> [:status, :ID])
# # newx.speed .= predict(m3, newx)
# # y = @combine(groupby(newx, :status), :μ = mean(:speed))
# # y1 = @select(@subset(y, :status .== "couple"), :μ)[1,1]
# # y0 = @select(@subset(y, :status .== "solo"), :μ)[1,1]
# # y1 - y0
#
#
#
# species = ("schaefferi", "fasciculatus")
# m = fit(MixedModel, @formula(speed2 ~ 1 + status + (1|ID)), @subset(data, :species .== species[2]))
#
# # using Conda
# # Conda.add("r-circular", channel = "conda-forge")
# # using RCall
# # @rlibrary circular
# # A1(x) = besseljx(1,x)/besseljx(0,x)
# # A1(x) = besseli(1, x)/besseli(0, x)
# # xs = range(eps(Float64),1,10000)
# # itp = LinearInterpolation(A1.(xs), xs, extrapolation_bc = Line())
# # A1inv(y) = itp(y)
# # x = (A1.(data[!, :tortuosity]));
# # UnicodePlots.histogram(x)
# # x = 0.1:0.1:1
# # A1.(x)
#
# # f(x, ::Symbol) = boxcox(x)[:x]
# # f(x, method::String) = DataWrangler.normalize(x; method)
# # f(x, fun::Function) = fun.(x)
# # pvals = []
# # for y in ys
# #     for method in (identity, "z-score", "min-max", "softmax", "sigmoid", :boxcox, A1)
# #         x = f(data[!, y], method)
# #         μ = mean(x)
# #         σ = std(x, mean = μ)
# #         push!(pvals, Dict(y => y, Symbol(method) => pvalue(ExactOneSampleKSTest(x, Normal(μ, σ)))))
# #     end
# # end
#
# rh = term(1) + term(:iteration) + term(:species) + (term(1)|term(:ID))
# function getp(y)
#     m = fit(MixedModel, term(y) ~ rh, data, Gamma())
#     tbl = coeftable(m)
#     @subset(DataFrame(tbl), :Name .== "iteration")[1, end]
# end
# pvals = Dict(y => getp(y) for y in ys)
#
# # try
#
# newx = DataFrame((tortuosity = 0.0, couple, ID) for ID in ("a", "b") for couple in (true, false))
# transform!(newx, [:couple, :ID] .=> categorical .=> [:couple, :ID])
# newx.tortuosity .= predict(m, newx)
# y = @combine(groupby(newx, :couple), :μ = mean(:tortuosity))
# y1 = @select(@subset(y, :couple .== true), :μ)[1,1]
# y0 = @select(@subset(y, :couple .== false), :μ)[1,1]
# y1 - y0
#
#
# # catch ex
# #     println(ex)
# # end
#
#
#
# # Plotting
#
# fig = Figure()
# ax = Axis(fig[1,1], aspect = DataAspect(), xlabel = "X (cm)", ylabel = "Y (cm)")
# radius = retrieve(conf, "arena", "radius", Float64)
# for xyt in df.xyt
#     i = findfirst(row -> sqrt(row.x^2 + row.y^2) ≥ radius, xyt)
#     if isnothing(i)
#         i = length(xyt)
#     end
#     lines!(ax, xyt.x[1:i], xyt.y[1:i])
# end
# lines!(ax, Circle(Point2f(0, 0), radius), color = :black)
# hidespines!(ax)
# save(joinpath(results, "tracks.png"), fig)
#
#
# g = groupby(df, ["species", "couple ID", "with female"])
# @transform!(g, :run = 1:length(:speed))
# g = groupby(df, ["species", "couple ID", "run"])
# for modality in (:speed, :tortuosity, :cordlength, :curvelength, :duration)
#     x = @combine(g, :line = Ref(Point2{Float64}.($"with female", $"$modality")))
#     axis = (; xticks = (0:1, ["solo", "pair"]), ylabel = "$modality")
#     for (k, x1) in pairs(groupby(x,:species))
#         xy = mapping(x1.line, layout = x1."couple ID")
#         layers = visual(Lines)
#         f = draw(layers * xy; axis)
#         save(joinpath(results, string(k..., " $modality.png")), f)
#     end
# end
#
# # accuracy as vector length
# degree2vector(α) = [reverse(sincosd(α))...]
# g = groupby(df, ["species", "couple ID", "with female"])
# x = @combine(g, :accuracy = norm(mean(degree2vector.($"exit azimuth"))))
# CSV.write(joinpath(results, "accuracy.csv"), x)
# g = groupby(x, ["species", "couple ID"])
# x = @combine(g, :line = Ref(Point2{Float64}.($"with female", :accuracy)))
# for (k, x1) in pairs(groupby(x, :species))
#     local fig
#     fig = draw(mapping(x1.line, layout=x1."couple ID") * visual(Lines), axis = (; ylabel = "vector length", xticklabelrotation = π/2, xticks = ([0, 1], ["solo", "couple"])))
#     save(joinpath(results, string(k..., " accuracy.png")), fig)
# end
#
