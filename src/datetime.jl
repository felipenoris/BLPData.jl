
# blpapi_defs.h

const BLPAPI_DATETIME_YEAR_PART         = 0x01
const BLPAPI_DATETIME_MONTH_PART        = 0x02
const BLPAPI_DATETIME_DAY_PART          = 0x04
const BLPAPI_DATETIME_OFFSET_PART       = 0x08
const BLPAPI_DATETIME_HOURS_PART        = 0x10
const BLPAPI_DATETIME_MINUTES_PART      = 0x20
const BLPAPI_DATETIME_SECONDS_PART      = 0x40
const BLPAPI_DATETIME_MILLISECONDS_PART = 0x80
const BLPAPI_DATETIME_FRACSECONDS_PART  = 0x80
const BLPAPI_DATETIME_DATE_PART         = BLPAPI_DATETIME_YEAR_PART | BLPAPI_DATETIME_MONTH_PART| BLPAPI_DATETIME_DAY_PART

const BLPAPI_DATETIME_TIME_PART         = BLPAPI_DATETIME_HOURS_PART | BLPAPI_DATETIME_MINUTES_PART | BLPAPI_DATETIME_SECONDS_PART
const BLPAPI_DATETIME_TIMEMILLI_PART    = BLPAPI_DATETIME_TIME_PART  | BLPAPI_DATETIME_MILLISECONDS_PART
const BLPAPI_DATETIME_TIMEFRACSECONDS_PART = BLPAPI_DATETIME_TIME_PART | BLPAPI_DATETIME_FRACSECONDS_PART

const DATETIME_WITH_TIMEZONE = BLPAPI_DATETIME_DATE_PART | BLPAPI_DATETIME_TIMEMILLI_PART | BLPAPI_DATETIME_OFFSET_PART

has_part(blp_datetime::BLPDateTime, part::UInt8) = blp_datetime.parts & part == part

function Dates.Date(blp_datetime::BLPDateTime)
    # checks that parts mask implies a pure Date value
    @assert blp_datetime.parts == BLPAPI_DATETIME_DATE_PART "BLPDateTime is not a Date. (parts mask = $P)."
    return Dates.Date(blp_datetime.year, blp_datetime.month, blp_datetime.day)
end

function Dates.DateTime(dt::BLPDateTime; ignore_offset::Bool=false)
    if !ignore_offset
        @assert !has_part(dt, BLPAPI_DATETIME_OFFSET_PART) "$dt is not a pure DateTime."
    end

    return Dates.DateTime(dt.year, dt.month, dt.day, dt.hours, dt.minutes, dt.seconds, dt.milliSeconds)
end

function Base.show(io::IO, dt::BLPDateTime)
    datetime_no_timezone = DateTime(dt, ignore_offset=true)
    show(io, datetime_no_timezone)

    if dt.offset >= 0
        print(io, '+')
    else
        print(io, '-')
    end

    abs_offset = abs(dt.offset)
    hours = div(abs_offset, 60)
    minutes = abs_offset - hours*60
    @printf(io, "%02d:%02d", hours, minutes)
end

function BLPDateTime(dt::Dates.DateTime, offset::Integer)
    return BLPDateTime(
            DATETIME_WITH_TIMEZONE,
            Dates.hour(dt),
            Dates.minute(dt),
            Dates.second(dt),
            Dates.millisecond(dt),
            Dates.month(dt),
            Dates.day(dt),
            Dates.year(dt),
            Int16(offset)
        )
end

function BLPDateTime(dt::Dates.DateTime)
    return BLPDateTime(
            BLPAPI_DATETIME_DATE_PART | BLPAPI_DATETIME_TIMEMILLI_PART,
            Dates.hour(dt),
            Dates.minute(dt),
            Dates.second(dt),
            Dates.millisecond(dt),
            Dates.month(dt),
            Dates.day(dt),
            Dates.year(dt),
            0
        )
end

function BLPDateTime(dt::Dates.Date)
    return BLPDateTime(
            BLPAPI_DATETIME_DATE_PART,
            0,
            0,
            0,
            0,
            Dates.month(dt),
            Dates.day(dt),
            Dates.year(dt),
            0
        )
end
