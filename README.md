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

PlotlySave reexports PlotlyBase so it is sufficient to do
```julia
using SPCSpectra

spc = SPC(filename)

## Plotting
using PlotlyBase
plotspc(data) = Plot([scatter(x = s[1], y = s[2]) for s in data])
plotspc(spc::SPC) = plotspc(spc.data)

plotspc(spc)
```

