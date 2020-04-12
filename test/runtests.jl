
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

@testset "Session" begin
    session = BLP.Session(service_download_timeout_msecs=2000)
    @test session.handle != C_NULL
    BLP.stop(session)
    BLP.destroy!(session)
    @test session.handle == C_NULL
    @test_throws ErrorException BLP.Session("refdata", port=9000)
end

const SESSION = BLP.Session()

@testset "Service" begin
    service = BLP.Service(SESSION, "refdata")

    println("operation names for $(service.name)")
    println(BLP.list_operation_names(service))

    @test BLP.has_operation(service, "HistoricalDataRequest")
    @test !BLP.has_operation(service, "HistoricalDatarequest")

    @testset "HistoricalDataRequest" begin
        op = BLP.get_operation(service, "HistoricalDataRequest")
        @test op.name == "HistoricalDataRequest"
        println(op)
    end
end

@testset "bdh" begin
    @time result = BLP.bdh(SESSION, "IBM US Equity", ["PX_LAST", "VWAP_VOLUME"], Date(2020, 1, 2), Date(2020, 1, 30))
    df = DataFrame(result)
    show(df)

    @testset "periodicity" begin
        x = BLP.bdh(SESSION, "PETR4 BS Equity", "PX_LAST", Date(2018, 2, 1), Date(2020, 2, 10), periodicity="YEARLY")
        @test length(x) == 2
    end

    @testset "options" begin
        options = Dict("periodicitySelection" => "YEARLY", "periodicityAdjustment" => "CALENDAR")
        x = BLP.bdh(SESSION, "PETR4 BS Equity", "PX_LAST", Date(2018, 2, 1), Date(2020, 2, 10), options=options)
        @test length(x) == 2
    end

    @testset "historical price" begin
        ticker = "PETR4 BS Equity"
        fields = [ "PX_LAST", "TURNOVER", "PX_BID", "PX_ASK", "EQY_WEIGHTED_AVG_PX", "EXCHANGE_VWAP" ]
        options = Dict(
            "periodicityAdjustment" => "CALENDAR",
            "periodicitySelection" => "DAILY",
            "currency" => "BRL",
            "pricingOption" => "PRICING_OPTION_PRICE",
            "nonTradingDayFillOption" => "ACTIVE_DAYS_ONLY",
            "nonTradingDayFillMethod" => "NIL_VALUE",
            "adjustmentFollowDPDF" => false,
            "adjustmentNormal" => false,
            "adjustmentAbnormal" => false,
            "adjustmentSplit" => false
        )

        x = BLP.bdh(SESSION, ticker, fields, Date(2019, 1, 1), Date(2019, 2, 10), options=options)
        println(DataFrame(x))
    end

    @testset "adjusted price" begin
        ticker = "PETR4 BS Equity"
        field = "PX_LAST"
        options = Dict(
            "periodicityAdjustment" => "CALENDAR",
            "periodicitySelection" => "DAILY",
            "currency" => "BRL",
            "pricingOption" => "PRICING_OPTION_PRICE",
            "nonTradingDayFillOption" => "ACTIVE_DAYS_ONLY",
            "nonTradingDayFillMethod" => "NIL_VALUE",
            "adjustmentFollowDPDF" => false,
            "adjustmentNormal" => true,
            "adjustmentAbnormal" => true,
            "adjustmentSplit" => true
        )

        x = BLP.bdh(SESSION, ticker, field, Date(2019, 1, 1), Date(2019, 2, 10), options=options)
        println(DataFrame(x))
    end
end

@testset "benchmarks" begin
    @time result = BLP.bdh(SESSION, "PETR4 BS Equity", ["PX_LAST", "VWAP_VOLUME"], Date(2020, 1, 2), Date(2020, 1, 30))
end

BLP.stop(SESSION)
