
@testset "Session" begin
    session = BLPData.Session(service_download_timeout_msecs=2000)
    @test session.handle != C_NULL
    BLPData.stop(session)
    BLPData.destroy!(session)
    @test session.handle == C_NULL
    @test_throws ErrorException BLPData.Session("refdata", port=9000)
end

SESSION = BLPData.Session()

@testset "Service" begin
    service = SESSION["refdata"]

    println("operation names for $(service.name)")
    println(BLPData.list_operation_names(service))

    @test BLPData.has_operation(service, "HistoricalDataRequest")
    @test !BLPData.has_operation(service, "HistoricalDatarequest")

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

    queue, corr_id = BLPData.send_request(SESSION, "refdata", "HistoricalDataRequest") do req
        push!(req["securities"], security)
        append!(req["fields"], fields)
        req["startDate"] = date_start
        req["endDate"] = date_end
    end

    resp = BLPData.parse_response_as(Dict, queue, corr_id)
    @test haskey(resp[1], :securityData)
    @test haskey(resp[1][:securityData], :fieldData)
    field_data = resp[1][:securityData][:fieldData]
    @test haskey(field_data[1], :PX_LAST)
    @test isa(field_data[1][:PX_LAST], Number)
    println(resp)

    BLPData.purge(queue)
end

@testset "bdh" begin
    @time result = BLPData.bdh(SESSION, "IBM US Equity", ["PX_LAST", "VWAP_VOLUME"], Date(2020, 1, 2), Date(2020, 1, 30))
    df = DataFrame(result)
    @test DataFrames.names(df) == [ :date, :PX_LAST, :VWAP_VOLUME ]
    @test size(df) == (20, 3)
    show(df)

    @testset "periodicity" begin
        df = DataFrame(BLPData.bdh(SESSION, "PETR4 BS Equity", "PX_LAST", Date(2018, 2, 1), Date(2020, 2, 10), periodicity="YEARLY"))
        @test DataFrames.names(df) == [ :date, :PX_LAST ]
        @test size(df) == (2, 2)
    end

    @testset "options" begin
        options = Dict("periodicitySelection" => "YEARLY", "periodicityAdjustment" => "CALENDAR")
        df = DataFrame(BLPData.bdh(SESSION, "PETR4 BS Equity", "PX_LAST", Date(2018, 2, 1), Date(2020, 2, 10), options=options))
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

        df = DataFrame(BLPData.bdh(SESSION, ticker, fields, Date(2019, 1, 1), Date(2019, 2, 10), options=options))
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

        df = DataFrame(BLPData.bdh(SESSION, ticker, field, Date(2019, 1, 1), Date(2019, 2, 10), options=options))
        @test DataFrames.names(df) == [ :date, :PX_LAST ]
        @test size(df) == (27, 2)
        show(df)
    end
end

@testset "bds" begin

    @testset "COMPANY_ADDRESS" begin
        df = DataFrame(BLPData.bds(SESSION, "PETR4 BS Equity", "COMPANY_ADDRESS"))
        @test DataFrames.names(df) == [:Address]
        @test df[end, :Address] == "Brazil"
        show(df)
    end

    @testset "DVD_HIST_GROSS_WITH_AMT_STAT" begin
        df = DataFrame(BLPData.bds(SESSION, "PETR4 BS Equity", "DVD_HIST_GROSS_WITH_AMT_STAT"))
        @test DataFrames.names(df) == [ Symbol("Declared Date"), Symbol("Ex-Date"), Symbol("Record Date"), Symbol("Payable Date"), Symbol("Dividend Amount"), Symbol("Dividend Frequency"), Symbol("Dividend Type"), Symbol("Amount Status") ]
    end
end

@testset "benchmarks" begin
    @time result = BLPData.bdh(SESSION, "PETR4 BS Equity", ["PX_LAST", "VWAP_VOLUME"], Date(2020, 1, 2), Date(2020, 1, 30))
end

BLPData.stop(SESSION)
