using Test
using SPCSpectra

@testset "SPCSpectra" begin
    dir = joinpath(pkgdir(SPCSpectra), "test", "data")
    filename = "4d_map.spc"
    path = joinpath(dir, filename)
    spc = SPC(path)
    # The data is from a Nicolet FT-IR spectrometer.
    # That is, a Fourier infrared spectrometer.
    @test spc.param_dict["SRC"] == "IR Source"
    @test spc.param_dict["MODEL"] == "Nicolet"
end
