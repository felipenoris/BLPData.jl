
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
