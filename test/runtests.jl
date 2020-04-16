
using Test, Dates, DataFrames
import BLP

@testset "Error Codes" begin
    error_string = BLP.blpapi_getLastErrorDescription(Int32(1))
    @test error_string == "BLPAPI_ERROR_UNKNOWN"
end

@testset "Version Info" begin
    vinfo = BLP.get_version_info()
    @test vinfo.major == 3
    println("BLPAPI Version: $vinfo")
end

@testset "BLPDateTime" begin
    today_dt = Dates.today()
    @test today_dt == Date(BLP.BLPDateTime(today_dt))
    now_dt = Dates.now()
    @test now_dt == DateTime(BLP.BLPDateTime(now_dt))
    show(BLP.BLPDateTime(now_dt, -180))
end

@testset "Session Options" begin
    @testset "Default" begin
        opt = BLP.SessionOptions()
        @test opt.handle != C_NULL
        server_host = BLP.get_server_host(opt)
        server_port = BLP.get_server_port(opt)
        client_mode = BLP.get_client_mode(opt)
        println("Default Server Host: $server_host")
        println("Default Server Port: $server_port")
        println("Default client mode: $client_mode")
        BLP.destroy!(opt)
        @test opt.handle == C_NULL
    end

    @testset "Constructor" begin
        opt = BLP.SessionOptions(host="my_host", port=9999, client_mode=BLP.BLPAPI_CLIENTMODE_DAPI)
        @test BLP.get_server_host(opt) == "my_host"
        @test BLP.get_server_port(opt) == 9999
        @test BLP.get_client_mode(opt) == BLP.BLPAPI_CLIENTMODE_DAPI
    end
end

@testset "BLPName" begin
    name1 = BLP.BLPName(:HEY_YOU) # uses blpapi_Name_create
    name2 = BLP.BLPName(:HEY_YOU) # uses blpapi_Name_create
    @test name1.handle == name2.handle

    # blpapi_Name_findName works only if blpapi_Name_create was used previously
    name3 = BLP.BLPName(BLP.blpapi_Name_findName(String(:HEY_YOU)))
    @test name3.handle == name1.handle

    BLP.destroy!(name1)
    @test name1.handle == C_NULL

    name4 = BLP.BLPName(BLP.blpapi_Name_findName(String(:HEY_YOU)))
    @test name2.handle == name4.handle
end

if haskey(ENV, "NO_BLP_SERVICE")
    @info("NO_BLP_SERVICE env variable is set. Skipping Terminal tests sets.")
else
    include("terminal_testsets.jl")
end
