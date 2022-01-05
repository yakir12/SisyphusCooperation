function donut()
  radius = retrieve(conf, "arena", "radius", Float64)
  ratio = retrieve(conf, "arena", "ratio", Float64)
  radius .* (1 .- ratio .* (1, -1)) ./ 2
end

function donut(xyt)
  r1, r2 = donut()
  i1 = findfirst(row -> sqrt(row.x^2 + row.y^2) ≥ r1, xyt)
  # i2 = findlast(row -> sqrt(row.x^2 + row.y^2) ≤ r2, xyt)
  i2 = findfirst(row -> sqrt(row.x^2 + row.y^2) ≥ r2, xyt)
  if isnothing(i2)
    i2 = length(xyt)
  end
  return i1, i2
end

function cordlength(xyt)
  i1, i2 = donut(xyt)
  p1 = Point2(xyt[i1].x, xyt[i1].y)
  p2 = Point2(xyt[i2].x, xyt[i2].y)
  norm(diff([p1, p2]))
end

function curvelength(xyt)
  i1, i2 = donut(xyt)
  p0 = Point2(xyt[i1].x, xyt[i1].y)
  s = 0.0
  for i in i1:i2
    p1 = Point2(xyt[i].x, xyt[i].y)
    s += norm(p1 - p0)
    p0 = p1
  end
  return s
end

function duration(xyt)
  i1, i2 = donut(xyt)
  xyt[i2].t - xyt[i1].t
end
