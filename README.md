# SPCSpectra

A module for working with .SPC files in Julia. SPC is a binary data format to store a variety of spectral data, developed by Galactic Industries Corporation in the '90s. Popularly used Thermo Fisher/Scientific software GRAMS/AI. Also used by others including Ocean Optics, Jobin Yvon Horiba. Can store a variety of spectrum including FT-IR, UV-VIS, X-ray Diffraction, Mass Spectroscopy, NMR, Raman and Fluorescence spectra.

The SPC file format can store either single or multiple y-values, and the x-values can either be given explicitly or even spaced x-values can be generated based on initial and final points as well as number of points. In addition the format can store various log data and parameters, as well as various information such as axis labels and scan type.

NOTE: This file is still in beta state and has not been fully tested.

## Acknowledgement
This package is highly inspired the python package [`spc` by rohanisaac](https://github.com/rohanisaac/spc).

## Features

1. Extracts header information
2. Store x and y data of all traces into a vector `data`. Single traces can be addressed by `spc.data[1]` (, `spc.data[2]`, `spc.data[3]`, ...)
3. Attempts to interpret x-, y-, and z-labels, as well as experiment type
4. Store z values of multifiles into a vector `zdata`

Currently only file version `0x4b` is supported. Data output is not yet implemented.


## Installation

```julia
julia> ]

pkg> add SPCSpectra
```

## Usage

```julia
using SPCSpectra

datadir = joinpath(pkgdir(SPCSpectra), "test", "data")
filenames = filter(endswith(r"\.spc"i), readdir(datadir; join=true))

spc = SPC(filenames[1])

# Plotting

using PlotlyBase
plotspc(spc::SPC) = plotspc(spc.data)
plotspc(data) = Plot([scatter(x = s[1], y = s[2]) for s in data])

plotspc(spc)
```

### Accessing data

In contrast to the original spc python package, all data elements contain both x and y values.
This is not a waste of storage as x arrays are stored by reference.

The following fields are currently supported.

metadata            | variable
------------------- | -----------
x-label             | spc.xlabel
y-label             | spc.ylabel
z-label             | spc.zlabel
Timestamp           | spc.timestamp
Experiment type     | spc.experimenttype
Log dictionary      | spc.param_dict
Log (remaining)     | spc.params


### File versions supported

File versions are given by the second bit in the file. Currently the library supports the following `fversn` bytes.

fversn | Description      | Support      | Notes
------ | ---------------- | ------------ | ----------------------------------------------------------------
0x4B   | New format (LSB) | Good         | 
0x4C   | New format (MSB) | None         | 
0x4D   | Old format       | None         |
0xCF   | SHIMADZU format  | None         | 

### Notes

- Used format specification from Universal Data Format Specification [1], [2]
- Loads entire file into memory
- Data uses variable naming as in SPC.H

### Todo

- support of other format versions
- data output / conversion
- integration of plot functions

## References

[1] "SPC file format", Wikipedia (<https://en.wikipedia.org/wiki/SPC_file_format>)  
[2] "Universal Data Format Specification" (PDF). (<https://ensembles-eu.metoffice.gov.uk/met-res/aries/technical/GSPC_UDF.PDF>)
