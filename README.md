# Cooperation in Sisyphus
This is all the code needed to retrieve and analyse the data from the cooperation in Sisyphus experiments. It produces the figures used in the article as well as some result `.csv` files.

## Requirements
There are two main "entry points":
1. `track`: Retrieve all the raw-data and auto-track the beetles and auto-calibrat the vidoes.
2. `analyse`: Retrieve the pre-processed tracks and analyse them.

Entry point #1, `track`, requires Matlab™ and Matlab™'s Computer Vision System toolbox installed, approximetly 40 GB of free storage space, and takes about an hour to complete. Entry point #2, `analyse`, has very little requirements. 

Both entry points require Julia to be installed (see [here](https://julialang.org/downloads/) for instructions on how to install Julia).

## How to use
1. Download this repository.
2. Start a new Julia REPL inside `track` or `analyse` depending on your needs.
3. Run the `main.jl` file (e.g. `include("main.jl")` in the REPL).
4. All the track, figures, and statistics have been generated in the `results` folder.

## Troubleshooting
Start a new Julia REPL (e.g. by double-clicking the Julia icon), and copy-paste:
```julia
import LibGit2, Pkg
entrypoint = "analyse"
path = mktempdir(; cleanup = false)
LibGit2.clone("https://github.com/yakir12/SisyphusCooperation", path) 
cd(joinpath(path, entrypoint))
include("main.jl")
@info "All the figures and data are in: $(joinpath(path, "results"))"
```
(assuming you want to get the pre-processed data, i.e. `analyse`)
