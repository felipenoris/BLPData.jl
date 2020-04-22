
using Test, Dates, DataFrames
import BLPData

if Sys.islinux() && haskey(ENV, "SKIP_LINUX_TESTS")
    @warn("Skipping tests for Linux.")
    exit()
end

@testset "Error Codes" begin
    error_string = BLPData.blpapi_getLastErrorDescription(Int32(1))
    @test error_string == "BLPAPI_ERROR_UNKNOWN"
end

@testset "Version Info" begin
    vinfo = BLPData.get_version_info()
    @test vinfo.major == 3
    println("BLPAPI Version: $vinfo")
end

@testset "BLPDateTime" begin
    today_dt = Dates.today()
    @test today_dt == Date(BLPData.BLPDateTime(today_dt))
    now_dt = Dates.now()
    @test now_dt == DateTime(BLPData.BLPDateTime(now_dt))
    show(BLPData.BLPDateTime(now_dt, -180))
end

@testset "Session Options" begin
    @testset "Default" begin
        opt = BLPData.SessionOptions()
        @test opt.handle != C_NULL
        server_host = BLPData.get_server_host(opt)
        server_port = BLPData.get_server_port(opt)
        client_mode = BLPData.get_client_mode(opt)
        println("Default Server Host: $server_host")
        println("Default Server Port: $server_port")
        println("Default client mode: $client_mode")
        BLPData.destroy!(opt)
        @test opt.handle == C_NULL
    end

    @testset "Constructor" begin
        opt = BLPData.SessionOptions(host="my_host", port=9999, client_mode=BLPData.BLPAPI_CLIENTMODE_DAPI)
        @test BLPData.get_server_host(opt) == "my_host"
        @test BLPData.get_server_port(opt) == 9999
        @test BLPData.get_client_mode(opt) == BLPData.BLPAPI_CLIENTMODE_DAPI
    end
end

@testset "BLPName" begin
    name1 = BLPData.BLPName(:HEY_YOU) # uses blpapi_Name_create
    name2 = BLPData.BLPName(:HEY_YOU) # uses blpapi_Name_create
    @test name1.handle == name2.handle

    # blpapi_Name_findName works only if blpapi_Name_create was used previously
    name3 = BLPData.BLPName(BLPData.blpapi_Name_findName(String(:HEY_YOU)))
    @test name3.handle == name1.handle

    BLPData.destroy!(name1)
    @test name1.handle == C_NULL

    name4 = BLPData.BLPName(BLPData.blpapi_Name_findName(String(:HEY_YOU)))
    @test name2.handle == name4.handle
end

if haskey(ENV, "NO_BLP_SERVICE")
    @info("NO_BLP_SERVICE env variable is set. Skipping Terminal tests.")
else
    include("terminal_testsets.jl")
end
