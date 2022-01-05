using CSV, DataFramesMeta

df = CSV.read("runs_G_15broken_final.csv", DataFrame)
bad = CSV.read("list of 15 broken runs.csv", DataFrame)
x = antijoin(df, bad, on = :rownumber)

CSV.write("runs2.csv", x)
