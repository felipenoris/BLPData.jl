
@testset "Session" begin
    session = BLPData.Session(service_download_timeout_msecs=2000)
    BLPData.get_opened_services_names(session) == BLPData.DEFAULT_SERVICE_NAMES
    @test BLPData.is_service_open(session, "refdata")
    @test session.handle != C_NULL
    BLPData.stop(session)
    BLPData.destroy!(session)
    @test session.handle == C_NULL
    @test_throws ErrorException BLPData.Session("refdata", port=9000)
end

SESSION = BLPData.Session()

@testset "Subscribe" begin
    sublist = BLPData.subscribe(SESSION, "//blp/mktdata/ticker/PETR4 BS Equity?fields=BID,ASK")
    BLPData.unsubscribe(SESSION, sublist)
end

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

@testset "bdp" begin
    @testset "single field" begin
        result = BLPData.bdp(SESSION, "PETR4 BS Equity", "PX_LAST")
        @test haskey(result, :PX_LAST)
        @test isa(result[:PX_LAST], Number)
    end

    @testset "many fields" begin
        result = BLPData.bdp(SESSION, "PETR4 BS Equity", ["PX_LAST", "VOLUME"])
        @test haskey(result, :PX_LAST)
        @test haskey(result, :VOLUME)
        @test isa(result[:PX_LAST], Number)
        @test isa(result[:VOLUME], Number)
    end

    @testset "many securities" begin
        result = BLPData.bdp(SESSION, ["PETR4 BS Equity", "VALE3 BS Equity"], ["PX_LAST", "VOLUME"])

        for (k, v) in result
            @test k == "PETR4 BS Equity" || k == "VALE3 BS Equity"
            @test haskey(v, :PX_LAST)
            @test isa(v[:PX_LAST], Number)
            @test isa(v[:VOLUME], Number)
        end
    end

    @testset "Invalid security" begin
        invalid_security = "INVALID SECURITY NAME"
        @test_throws BLPData.BLPResultErrException BLPData.bdp(SESSION, invalid_security, "TICKER")

        try
            BLPData.bdp(SESSION, invalid_security, "TICKER")
        catch err
            @test err.err.code == 3
            @test err.err.category == "BAD_SEC"
            @test err.err.subcategory == "INVALID_SECURITY"
        end
    end
end

@testset "bdh" begin
    result = BLPData.bdh(SESSION, "IBM US Equity", ["PX_LAST", "VWAP_VOLUME"], Date(2020, 1, 2), Date(2020, 1, 30))
    df = DataFrame(result)
    @test DataFrames.names(df) == [ "date", "PX_LAST", "VWAP_VOLUME" ]
    @test size(df) == (20, 3)
    show(df)

    @testset "periodicity" begin
        df = DataFrame(BLPData.bdh(SESSION, "PETR4 BS Equity", "PX_LAST", Date(2018, 2, 1), Date(2020, 2, 10), periodicity="YEARLY"))
        @test DataFrames.names(df) == [ "date", "PX_LAST" ]
        @test size(df) == (2, 2)
    end

    @testset "options" begin
        options = Dict("periodicitySelection" => "YEARLY", "periodicityAdjustment" => "CALENDAR")
        df = DataFrame(BLPData.bdh(SESSION, "PETR4 BS Equity", "PX_LAST", Date(2018, 2, 1), Date(2020, 2, 10), options=options))
        @test DataFrames.names(df) == [ "date", "PX_LAST" ]
        @test size(df) == (2, 2)
    end

    @testset "Exceptions" begin
        @test_throws BLPData.BLPResultErrException BLPData.bdh(SESSION, "INVALID SECURITY Equity", "PX_LAST", Date(2020, 4, 1), Date(2020, 4, 30))
        @test_throws BLPData.BLPResultErrException BLPData.bdh(SESSION, "PETR4 BS Equity", ["PX_LAST", "INVALID FIELD"], Date(2020, 4, 1), Date(2020, 4, 30))

        @testset "NoUnwrap" begin
            bdh_result = BLPData.bdh(SESSION, "PETR3 BS Equity", ["PX_LAST", "VOLUMExxx"], Date(2020, 4, 1), Date(2020, 4, 30), error_handling=BLPData.NoUnwrap())
            @test ismissing(bdh_result.field_data_vec[1].result.VOLUMExxx)
            @test isa(bdh_result.field_exceptions[:VOLUMExxx], BLPData.FieldErr)
        end
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
        @test DataFrames.names(df) == [ "date", "PX_LAST", "TURNOVER", "PX_BID", "PX_ASK", "EQY_WEIGHTED_AVG_PX", "EXCHANGE_VWAP" ]
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
        @test DataFrames.names(df) == [ "date", "PX_LAST" ]
        @test size(df) == (27, 2)
        show(df)
    end
end

@testset "bdh_intraday_ticks" begin
    @testset "Single security one field" begin
        d0 = DateTime(2020, 4, 27, 13)
        d1 = DateTime(2020, 4, 27, 13, 5)
        res = BLPData.bdh_intraday_ticks(SESSION, "PETR4 BS Equity", ["ASK"], d0, d1)
        @test length(res) > 10
        @test length(res) < 30 # 20 max
        for t in res
            @test t.type == :ASK
        end
    end

    @testset "Single security multiple fields" begin
        d0 = DateTime(2020, 4, 27, 13)
        d1 = DateTime(2020, 4, 27, 13, 5)
        res = BLPData.bdh_intraday_ticks(SESSION, "PETR4 BS Equity", ["TRADE", "BID", "ASK"], d0, d1)
        @test length(res) > 10
        @test length(res) < 50
        show(DataFrame(res))
    end

    @testset "Multiple securities" begin
        d0 = DateTime(2020, 4, 27, 13)
        d1 = DateTime(2020, 4, 27, 13, 5)
        res = BLPData.bdh_intraday_ticks(SESSION, ["PETR4 BS Equity", "VALE3 BS Equity"], ["TRADE", "BID", "ASK"], d0, d1)
        @test haskey(res, "PETR4 BS Equity")
        @test haskey(res, "VALE3 BS Equity")
        @test length(res["PETR4 BS Equity"]) > 10
        @test length(res["PETR4 BS Equity"]) < 50
        @test length(res["VALE3 BS Equity"]) > 10
        @test length(res["VALE3 BS Equity"]) < 40
    end
end

@testset "bds" begin
    @testset "COMPANY_ADDRESS" begin
        df = DataFrame(BLPData.bds(SESSION, "PETR4 BS Equity", "COMPANY_ADDRESS"))
        @test DataFrames.names(df) == [ "Address" ]
        @test df[end, :Address] == "Brazil"
        show(df)
    end

    @testset "DVD_HIST_GROSS_WITH_AMT_STAT" begin
        df = DataFrame(BLPData.bds(SESSION, "PETR4 BS Equity", "DVD_HIST_GROSS_WITH_AMT_STAT"))
        @test DataFrames.names(df) == [ "Declared Date", "Ex-Date", "Record Date", "Payable Date", "Dividend Amount", "Dividend Frequency", "Dividend Type", "Amount Status" ]
    end
end

@testset "benchmarks" begin
    @testset "single ticker" begin
        println("single ticker benchmark")
        @time result = BLPData.bdh(SESSION, "PETR4 BS Equity", ["PX_LAST", "VWAP_VOLUME"], Date(2020, 1, 2), Date(2020, 1, 30))
    end

    tickers = [ "PETR4 BS Equity",
                "PETR3 BS Equity",
                "VALE3 BS Equity",
                "BBDC4 BS Equity",
                "BBDC3 BS Equity",
                "ITUB4 BS Equity",
                "B3SA3 BS Equity",
                "ABEV3 BS Equity",
                "BBAS3 BS Equity",
                "ITSA4 BS Equity",
                "MGLU3 BS Equity",
                "LREN3 BS Equity",
                "VIVT4 BS Equity"
             ]

    @testset "Async bds" begin
        println("Async bds benchmark")
        @time result = BLPData.bds(SESSION, tickers, "DVD_HIST_GROSS_WITH_AMT_STAT")
        @test isa(result, Dict)

        for ticker in tickers
            @test haskey(result, ticker)
        end
    end

    @testset "Async bdh many fields" begin
        println("Async bdh benchmark")
        @time result = BLPData.bdh(SESSION, tickers, ["PX_LAST", "VWAP_VOLUME"], Date(2020, 1, 2), Date(2020, 1, 30))
        @test isa(result, Dict)

        for ticker in tickers
            @test haskey(result, ticker)
            @test isa(result[ticker], Vector)

            for row in result[ticker]
                @test isa(row, NamedTuple)
                @test haskey(row, :PX_LAST)
                @test haskey(row, :VWAP_VOLUME)
                @test isa(row[:PX_LAST], Number)
                @test isa(row[:VWAP_VOLUME], Number)
            end
        end
    end

    @testset "Async bdh many fields" begin
        println("Async bdh benchmark")
        @time result = BLPData.bdh(SESSION, tickers, "PX_LAST", Date(2020, 1, 2), Date(2020, 1, 30))
        @test isa(result, Dict)

        for ticker in tickers
            @test haskey(result, ticker)
            @test isa(result[ticker], Vector)

            for row in result[ticker]
                @test isa(row, NamedTuple)
                @test haskey(row, :PX_LAST)
                @test isa(row[:PX_LAST], Number)
            end
        end
    end

    @testset "bdp multiple securities" begin
        println("bdp multiple securities")
        @time result = BLPData.bdp(SESSION, tickers, ["PX_LAST", "VOLUME"])
        @test isa(result, Dict)

        for ticker in tickers
            @test haskey(result, ticker)
            @test isa(result[ticker], NamedTuple)
            @test isa(result[ticker].PX_LAST, Number)
            @test isa(result[ticker].VOLUME, Number)
        end
    end
end

BLPData.stop(SESSION)

#=
single ticker benchmark
  0.294486 seconds (1.99 k allocations: 99.656 KiB)
Async bds benchmark
  0.584568 seconds (1.05 M allocations: 53.660 MiB, 1.98% gc time)
Async bdh benchmark
  0.334141 seconds (31.69 k allocations: 1.558 MiB, 4.23% gc time)
Async bdh benchmark
  0.333756 seconds (20.68 k allocations: 1.030 MiB)
bdp multiple securities
  0.418478 seconds (1.70 k allocations: 93.312 KiB)
=#
