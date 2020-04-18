
@testset "Session" begin
    session = BLP.Session(service_download_timeout_msecs=2000)
    @test session.handle != C_NULL
    BLP.stop(session)
    BLP.destroy!(session)
    @test session.handle == C_NULL
    @test_throws ErrorException BLP.Session("refdata", port=9000)
end

SESSION = BLP.Session()

@testset "Service" begin
    service = SESSION["refdata"]

    println("operation names for $(service.name)")
    println(BLP.list_operation_names(service))

    @test BLP.has_operation(service, "HistoricalDataRequest")
    @test !BLP.has_operation(service, "HistoricalDatarequest")

    @testset "HistoricalDataRequest" begin
        op = service["HistoricalDataRequest"]
        @test op.name == "HistoricalDataRequest"
        println(op)
    end
end

@testset "generic request/response" begin
    security = "PETR4 BS Equity"
    fields = [ "PX_LAST", "VOLUME" ]
    date_start = Date(2020, 4, 1)
    date_end = Date(2020, 4, 16)

    corr_id = BLP.send_request(SESSION, "refdata", "HistoricalDataRequest") do req
        push!(req["securities"], security)
        append!(req["fields"], fields)
        req["startDate"] = date_start
        req["endDate"] = date_end
    end

    resp = BLP.parse_response_as(Dict, SESSION, corr_id)
    @test haskey(resp[1], :securityData)
    @test haskey(resp[1][:securityData], :fieldData)
    field_data = resp[1][:securityData][:fieldData]
    @test haskey(field_data[1], :PX_LAST)
    @test isa(field_data[1][:PX_LAST], Number)
    println(resp)
end

@testset "bdh" begin
    @time result = BLP.bdh(SESSION, "IBM US Equity", ["PX_LAST", "VWAP_VOLUME"], Date(2020, 1, 2), Date(2020, 1, 30))
    df = DataFrame(result)
    @test DataFrames.names(df) == [ :date, :PX_LAST, :VWAP_VOLUME ]
    @test size(df) == (20, 3)
    show(df)

    @testset "periodicity" begin
        df = DataFrame(BLP.bdh(SESSION, "PETR4 BS Equity", "PX_LAST", Date(2018, 2, 1), Date(2020, 2, 10), periodicity="YEARLY"))
        @test DataFrames.names(df) == [ :date, :PX_LAST ]
        @test size(df) == (2, 2)
    end

    @testset "options" begin
        options = Dict("periodicitySelection" => "YEARLY", "periodicityAdjustment" => "CALENDAR")
        df = DataFrame(BLP.bdh(SESSION, "PETR4 BS Equity", "PX_LAST", Date(2018, 2, 1), Date(2020, 2, 10), options=options))
        @test DataFrames.names(df) == [ :date, :PX_LAST ]
        @test size(df) == (2, 2)
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

        df = DataFrame(BLP.bdh(SESSION, ticker, fields, Date(2019, 1, 1), Date(2019, 2, 10), options=options))
        @test DataFrames.names(df) == [ :date, :PX_LAST, :TURNOVER, :PX_BID, :PX_ASK, :EQY_WEIGHTED_AVG_PX, :EXCHANGE_VWAP ]
        @test size(df) == (27, 7)
        show(df)
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

        df = DataFrame(BLP.bdh(SESSION, ticker, field, Date(2019, 1, 1), Date(2019, 2, 10), options=options))
        @test DataFrames.names(df) == [ :date, :PX_LAST ]
        @test size(df) == (27, 2)
        show(df)
    end
end

@testset "benchmarks" begin
    @time result = BLP.bdh(SESSION, "PETR4 BS Equity", ["PX_LAST", "VWAP_VOLUME"], Date(2020, 1, 2), Date(2020, 1, 30))
end

BLP.stop(SESSION)
