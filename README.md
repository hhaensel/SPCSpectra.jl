# SPCSpectra

Package to read spectroscopic files in the spc format.

This package is a julia implementation of the pythonpackage `spc` by rohanisaac
of [spc](https://github.com/rohanisaac/spc).


## Installation

```julia
using Pkg
Pkg.add("https://github.com/hhaensel/SPCSpectra")
```
or
```julia
]add https://github.com/hhaensel/SPCSpectra"
```

## Usage

```julia
using SPCSpectra

spc = SPC(filename)

# Plotting
using PlotlyBase

plotspc(spc::SPC) = Plot([scatter(x = s[1], y = s[2]) for s in spc.data])

plotspc(spc)
```

