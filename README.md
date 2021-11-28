# Cooperation in Sisyphus
This is all the code needed to retrieve and analyse the data from the cooperation in Sisyphus experiments. It produces the figures used in the article as well as some result `.csv` files.

## Requirements
There are two main "entry points":
1. Retrieve all the raw-data and process everything from scratch. This includes auto-tracking the beetles, auto-calibrating the vidoes, and processing all the data used in the analysis, as well as the figures and stats.
2. Retrieve the pre-processed data and analyse it (resulting in the stats).

Entry point #1 requires Matlab™ and Matlab™'s Computer Vision System toolbox installed, approximetly 40 GB of free storage space, and takes about an hour to complete. Entry point #2 has very little requirements. 

Both entry points require Julia to be installed (see [here](https://julialang.org/downloads/) for instructions on how to install Julia).

## How to use
1. Download this repository.
2. Start a new Julia REPL inside `entrypoint1` or `entrypoint2` depending on your needs.
3. Run the `main.jl` file (e.g. `include("main.jl")` in the REPL).
4. All the figures and statistics have been generated in the `results` folder.

## Troubleshooting
Start a new Julia REPL (e.g. by double-clicking the Julia icon), and copy-paste:
```julia
import LibGit2, Pkg
entrypoint = "entrypoint2"
mktempdir() do path
  LibGit2.clone("https://github.com/yakir12/SisyphusCooperation", path) 
  cd(joinpath(path, entrypoint))
  include(joinpath(path, entrypoint, "main.jl"))
end
```
(assuming you want to get the pre-processed data, i.e. `entrypoint2`)
