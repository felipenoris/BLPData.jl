
using Test, Dates
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

@testset "Session" begin
    session = BLP.Session("//blp/mktdata", "//blp/refdata", service_download_timeout_msecs=2000)
    @test session.handle != C_NULL
    BLP.stop(session)
    BLP.destroy!(session)
    @test session.handle == C_NULL
    @test_throws ErrorException BLP.Session("//blp/refdata", port=9000)
end

@testset "Service" begin
    session = BLP.Session("//blp/refdata")
    service = BLP.Service(session, "//blp/refdata")

    println("operation names for $(service.name)")
    println(BLP.list_operation_names(service))

    #for opindex in 1:BLP.get_num_operations(service)
    #    println(BLP.get_operation(service, opindex))
    #end

    @test BLP.has_operation(service, "HistoricalDataRequest")
    @test !BLP.has_operation(service, "HistoricalDatarequest")

    @testset "HistoricalDataRequest" begin
        op = BLP.get_operation(service, "HistoricalDataRequest")
        @test op.name == "HistoricalDataRequest"
        #println(op)
    end
end

@testset "Request" begin
    session = BLP.Session("//blp/refdata")
    service = BLP.Service(session, "//blp/refdata")

    req = BLP.Request(service, "HistoricalDataRequest")
    elements = BLP.Element(req)
    elements_schema = BLP.SchemaElementDefinition(elements)
    @test elements_schema.name.symbol == :HistoricalDataRequest

    push!(req["securities"], "IBM US Equity")
    push!(req["fields"], "PX_LAST", "VWAP_VOLUME")
    req["startDate"] = Date(2020, 1, 2)
    req["endDate"] = Date(2020, 1, 31)

    per = req["periodicitySelection"]
    per_schema = BLP.SchemaElementDefinition(per)
    println(per_schema)

    BLP.send(req)
end
