# Autotrack

A simple auto-tracker for videos of dark beetles walking on a brighter background.

## Install
You'll need a new version of Julia installed (see [here](https://julialang.org/downloads/) for instructions on how to install Julia).

Start a new Julia REPL (e.g. by double-clicking the Julia icon). In the new terminal, type a right-hand-square-bracket (`]`) and then `add https://github.com/yakir12/Autotrack.jl`, followed by pressing `Enter`:
```julia
] add https://github.com/yakir12/Autotrack.jl
```

Each time you're going to use this package you'll have to run the following when starting a Julia session:
```julia
using Autotrack
```

## Use
The main function is `process_tracks(csvfile)` where `csvfile` is the full path to the `.csv` file that contains all your runs. Each row in this file has the file name of the video containing the trajectory of the animal, the time stamp of when the run begins in the video file, and the time stamp of when it ends. The video file name must not include the full path to the video file but must include the file's extension (e.g. `name.MTS`). The time stamps must be in the following format: `minutes:seconds,milliseconds` or `hours:minutes:seconds,milliseconds` (e.g. 14:24,087). The column names of the file must be `file`, `start`, and `stop`.

Two additional but optional arguments are:
1. `video_dir`: This is the full path to the folder containing all the video files mentioned in the `csvfile`. 
2. `result_dir`: This is the full path to the folder where you want all the results to be saved to.

These default to the `csvfile`'s directory. To change one or both specify them in the call to `process_tracks`, for example, to change the directory where all the video files are:
```julia
process_tracks("/the/full/path/to/the/csv/file.csv", video_dir = "/some/path/to/where/all/the/videos/are")
```

Running this function will save a short video showing the track in red and a `.csv` file with the coordinates of the track as a function of time. Check the short video to see if the tracking worked or not before using these results.

## Troubleshoot
### The tracker doesn't detect my beetle at all
Try shifting the starting time-stamp a second or two forward. For example, instead of 05:57,9 try 5:59 or later.
### My head/hand occludes the beetle, messing up the track
If you're only interested in the walking speed of the beetle, and you assume it is more or less the same across the track, change the start and stop time so that only the good part of the track is included. This way you're excluding the corrupt part of the track.
