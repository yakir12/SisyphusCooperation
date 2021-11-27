# Cooperation in Sisyphus
This is all the code needed to retrieve and analyse the data from the cooperation in Sisyphus experiments. It produces the figures used in the article as well as some result `.csv` files.

## Requirements
There are two main "entry points":
1. retrieve all the raw-data and process everything from scratch. This includes auto-tracking the beetles, auto-calibrating the vidoes, and processing all the data used in the analysis, as well as the figures and stats.
2. retrieve the pre-processed data and analyse it (resulting in the stats).

Entry point #1 requires Matlab™ and Matlab™'s Computer Vision System toolbox installed, approximetly 40 GB free space, and takes about an hour to complete. Entry point #2 has very little requirements. 

Both entry points require a new version of Julia installed (see [here](https://julialang.org/downloads/) for instructions on how to install Julia).

## How to use
1. Download this repository (e.g. `git clone https://github.com/yakir12/SisyphusCooperation`)
2. Start a new Julia REPL inside `entrypoint1` or `entrypoint2` depending on your needs. One way to accomplish this is with `cd("<path>")` where `<path>` is the path to the desired folder. For instance, if you've downloaded this git-repository to your home directory, then `cd(joinpath(homedir(), "SisyphusCooperation/entrypoint2"))` should work.
3. Then simply paste:
   ```julia
   include("main.jl")
   ```
4. All the figures and statistics have been generated in the `results` folder.

If this did not work, try the next section.

## Troubleshooting
Start a new Julia REPL (e.g. by double-clicking the Julia icon), and copy-paste:
```julia
import LibGit2, Pkg
mktempdir() do path
  LibGit2.clone("https://github.com/yakir12/SisyphusCooperation", path) 
  include(joinpath(path, "entrypoint2", "main.jl"))
end
```
(assuming you want to get the pre-processed data)
