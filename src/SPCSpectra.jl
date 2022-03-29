module SPCSpectra

using Dates

export SPC

mutable struct SPC
    data::Vector{NTuple{2, Vector{<:Number}}}
    xlabel::String
    ylabel::String
    zlabel::String
    experimenttype::String
    timestamp::DateTime
    param_dict::Dict{String, String}
    params::Vector{String}
end

# Adaptation of the pythonpackage spc by rohanisaac

# byte positon of various parts of the file
# head_siz = 512
# old_head_siz = 256
subhead_siz = 32
log_siz = 64

"Units for x,z,w axes."
const fxtype_op = ["Arbitrary",
                    "Wavenumber (cm-1)",
                    "Micrometers (um)",
                    "Nanometers (nm)",
                    "Seconds ",
                    "Minutes", "Hertz (Hz)",
                    "Kilohertz (KHz)",
                    "Megahertz (MHz) ",
                    "Mass (M/z)",
                    "Parts per million (PPM)",
                    "Days",
                    "Years",
                    "Raman Shift (cm-1)",
                    "eV",
                    "XYZ text labels in fcatxt (old 0x4D version only)",
                    "Diode Number",
                    "Channel",
                    "Degrees",
                    "Temperature (F)",
                    "Temperature (C)",
                    "Temperature (K)",
                    "Data Points",
                    "Milliseconds (mSec)",
                    "Microseconds (uSec) ",
                    "Nanoseconds (nSec)",
                    "Gigahertz (GHz)",
                    "Centimeters (cm)",
                    "Meters (m)",
                    "Millimeters (mm)",
                    "Hours"]

"Units y-axis."
const fytype_op = ["Arbitrary Intensity",
                    "Interferogram",
                    "Absorbance",
                    "Kubelka-Munk",
                    "Counts",
                    "Volts",
                    "Degrees",
                    "Milliamps",
                    "Millimeters",
                    "Millivolts",
                    "Log(1/R)",
                    "Percent",
                    "Intensity",
                    "Relative Intensity",
                    "Energy",
                    "",
                    "Decibel",
                    "",
                    "",
                    "Temperature (F)",
                    "Temperature (C)",
                    "Temperature (K)",
                    "Index of Refraction [N]",
                    "Extinction Coeff. [K]",
                    "Real",
                    "Imaginary",
                    "Complex"]

const fytype_op2 = ["Transmission",
                    "Reflectance",
                    "Arbitrary or Single Beam with Valley Peaks",
                    "Emission"]

const fexper_op = ["General SPC",
                    "Gas Chromatogram",
                    "General Chromatogram",
                    "HPLC Chromatogram",
                    "FT-IR, FT-NIR, FT-Raman Spectrum or Igram",
                    "NIR Spectrum",
                    "UV-VIS Spectrum",
                    "X-ray Diffraction Spectrum",
                    "Mass Spectrum ",
                    "NMR Spectrum or FID",
                    "Raman Spectrum",
                    "Fluorescence Spectrum",
                    "Atomic Spectrum",
                    "Chromatography Diode Array Spectra"]

flag_bits(n) = BitVector(digits(n, base = 2, pad = 8 * sizeof(n)))

read_data(io::IO, T::DataType) = ltoh(read(io, T))
read_data(io::IO, ::Type{String}, n::Integer) = strip(String(read(io, n)), '\0')
read_data(io::IO, T::DataType, n::Integer...) = ltoh.(reshape(reinterpret(T, read(io, prod(n) * sizeof(T))), Int64.(n)...))
read_data(io::IO, TT::Union{NTuple{N, DataType} where N, Vector{DataType}}) = ltoh.(read.(Ref(io), TT))

"""
    SPC(filename::AbstractString)

Construct SPC objects.
"""
function SPC(filename::AbstractString)
    content = read(filename)
    io = IOBuffer(content)

    ftflg, fversn = content[1:2]
    # --------------------------------------------
    # NEW FORMAT (LSB)
    # --------------------------------------------
    fversn == 0x4b || return "Reading of file version $(repr(fversn)) not implemented"

    ftflg = read_data(io, UInt8)
    fversn = read_data(io, UInt8)
    fexper = read_data(io, UInt8)
    fexp = read_data(io, UInt8)
    fnpts = read_data(io, Int32)
    ffirst = read_data(io, Float64)
    flast = read_data(io, Float64)
    fnsub = read_data(io, Int32)
    fxtype = read_data(io, UInt8)
    fytype = read_data(io, UInt8)
    fztype = read_data(io, UInt8)
    fpost = read_data(io, UInt8)
    fdate = read_data(io, Int32)
    
    fres = read_data(io, String, 9)
    fsource = read_data(io, String, 9)
    fpeakpt = read_data(io, Int16)
    fspare  = read_data(io, String, 32)
    fcmnt = read_data(io, String, 130)
    fcatxt = read_data(io, String, 30)
    flogoff = read_data(io, Int32)
    fmods = read_data(io, Int32)
    fprocs = read_data(io, UInt8)
    flevel = read_data(io, UInt8)
    fsampin = read_data(io, Int16)
    ffactor = read_data(io, Float32)
    fmethod = read_data(io, String, 48)
    fzinc = read_data(io, Float32)
    fwplanes = read_data(io, Int32)
    fwinc = read_data(io, Float32)
    fwtype = read_data(io, UInt8)
    freser = read_data(io, String, 187)

    # Flag bits
    tsprec, tcgram, tmulti, trandm, tordrd, talabs, txyxys, txvals = flag_bits(ftflg)

    # Convert date time to appropriate format
    year = fdate >> 20
    month = (fdate >> 16) % (2^4)
    day = (fdate >> 11) % (2^5)
    hour = (fdate >> 6) % (2^5)
    minute = fdate % (2^6)
    timestamp = DateTime(year, month, day, hour, minute)

    # remove multiple spaces
    cmnt = replace(fcmnt, r"\s+" => " ")
        
    # figure out type of file
    dat_multi = fnsub > 1

    dat_fmt = if txyxys
        # x values are given
        "-xy"
    elseif txvals
        # only one subfile, which contains the x data
        dat_fmt = "x-y"
    else        
        # no x values are given, but they can be generated
        dat_fmt = "gx-y"
    end

    println("$dat_fmt($fnsub)")

    x = if ! txyxys
        # txyxys don't have global x data
        if txvals
            # if global x data is given
            read_data(io, Float32, fnpts)
        else
            # otherwise generate them
            range(ffirst, flast; length=fnpts) |> collect
        end
    end
    # make a list of subfiles
    sub = []

    # if subfile directory is given
    if dat_fmt == "-xy" && fnpts > 0
        directory = true
        # loop over entries in directory
        for i in 1:fnsub
            ssfposn, ssfsize, ssftime = read_data(io, (Int32, Int32, Float32))
            # add sufile, load defaults for npts and exp
            pos = position(io)
            seek(io, ssfposn) # io buffer position is zero-based!
            xloc, y = subFile(io, 0, 0, true, tsprec, tmulti)
            seek(io, pos)
            push!(sub, (isnothing(xloc) ? x : xloc, y))
        end
    else
        # don't have directory, for each subfile
        for i in 1:fnsub
            xloc, y = subFile(io, fnpts, fexp, txyxys, tsprec, tmulti)
            push!(sub, (isnothing(xloc) ? x : xloc, y))
        end
    end
    # if log data exists
    # flog offset to log data offset not zero (bytes)
    param_dict = Dict{String, String}()
    params = String[]  # put the rest into a list
    if flogoff > 0
        log_head_end = flogoff + log_siz
        io_log = IOBuffer(content[flogoff+1:log_head_end])
        # logstc_str = "<iiiii44s"
        logsizd, logsizm, logtxto, logbins, logdsks = read_data(io_log, Int32, 5)
        logspar = read_data(io_log, String, 44)
        log_pos = flogoff + logtxto

        log_end_pos = flogoff + logsizd

        # line endings: get rid of any '\r' and then split on '\n'
        log_content = split(strip(String(content[log_pos + 1:log_end_pos]), ['\0', '\r', '\n']), r"\r?\n")

        # split log data into dictionary based on =
        for x in log_content
            if occursin("=", x)
                # stop it from breaking if there is more than 1 =
                key, value = split(x, "=")[1:2]
                push!(param_dict, key => strip(value, '\0'))
            else
                push!(params, x)
            end
        end
    end

    labels = [
        get(fxtype_op, fxtype + 1, "Unknown"),
        get(fytype_op, fytype + 1, get(fytype_op2, fytype - 127, "Unknown")),
        get(fxtype_op, fztype + 1, "Unknown")
    ]
    
    # --------------------------
    # check if labels are included as text
    # --------------------------

    # split it based on '\0' character
    # format x, y, z
    if talabs
        for (i, s) in enumerate(split(fcatxt, '\0', keepempty = false))
            isempty(s) || (labels[i] = s)
        end
    end
    SPC(sub, labels..., get(fexper_op, fexper + 1, "Unknown"), timestamp, param_dict, params)
end

"""
    subFile(io::IO, fnpts, fexp, txyxy, tsprec, tmulti)

Process each subfile passed to it, extracts header information and data
information and places them in data members
Data
- x: x-data (optional)
- y: y-data
- y_int: integer y-data if y-data is not floating
"""
function subFile(io::IO, fnpts, fexp, txyxy, tsprec, tmulti)
    # extract subheader info
    subflgs, subexp, subindx, subtime, subnext, subnois, subnpts, subscan, subwlevel, subresv = read_subheader(io)

    pts = txyxy ? subnpts : fnpts

    # Choosing exponent
    # -----------------
    # choose local vs global exponent depending on tmulti
    exp = tmulti ? subexp : fexp

    # Make sure it is reasonable, if it out of range zero it
    (-128 < exp <= 128) || (exp = 0)

    # --------------------------
    # if x_data present
    # --------------------------
    x = if txyxy
        # x_str = '<' + 'i' * pts
        x_raw = read_data(io, Int32, pts)
        (2.0f0^(exp - 32)) .* x_raw
    else
        nothing
    end
    # --------------------------
    # extract y_data
    # --------------------------
    y = if exp == 128
        # Floating y-values
        read_data(io, Float32, pts)
    else
        # integer format
        if tsprec
            # 16 bit
            y_raw16 = read_data(io, Int16, pts)
            (2.0f0^(exp - 16)) .* y_raw16
        else
            # 32 bit, using size of subheader to figure out data type
            y_raw = read_data(io, Int32, pts)
            (2.0f0^(exp - 32)) .* y_raw
        end
    end
    x, y
end

"""
    read_subheader(io::IO)

Return the subheader as a list:
-------
10 item list with the following data members:
    [1] subflgs
    [2] subexp
    [3] subindx
    [4] subtime
    [5] subnext
    [6] subnois
    [7] subnpts
    [8] subscan
    [9] subwlevel
    [10] subresv
"""
function read_subheader(io::IO)
    subflgs = read_data(io, UInt8)
    subexp = read_data(io, UInt8)
    subindx = read_data(io, Int16)
    subtime = read_data(io, Float32)
    subnext = read_data(io, Float32)
    subnois = read_data(io, Float32)
    subnpts = read_data(io, Int32)
    subscan = read_data(io, Int32)
    subwlevel = read_data(io, Float32)
    subresv = read_data(io, String, 4)

    subflgs, subexp, subindx, subtime, subnext, subnois, subnpts, subscan, subwlevel, subresv
end

end # module
