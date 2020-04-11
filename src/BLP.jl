
module BLP

using Dates

include("deps.jl")
include("types.jl")
include("c.jl")
include("constant.jl")
include("blpname.jl")
include("session.jl")
include("schema.jl")
include("print.jl")

function __init__()
    check_deps()
end

function error_check(code::Cint)
    if code != 0
        error(blpapi_getLastErrorDescription(code))
    end

    nothing
end

function error_check(code::Cint, ctx_msg::AbstractString)
    if code != 0
        error("$ctx_msg: $(blpapi_getLastErrorDescription(code))")
    end

    nothing
end

function ptr_check(ptr::Ptr{Cvoid})
    if ptr == C_NULL
        error("Got a NULL pointer.")
    end

    nothing
end

function ptr_check(ptr::Ptr{Cvoid}, ctx_msg::AbstractString)
    if ptr == C_NULL
        error("$ctx_msg: got a NULL pointer.")
    end

    nothing
end

blp_date_string(date::Date) :: String = Dates.format(date, dateformat"yyyymmdd")

"""
    get_version_info() :: VersionInfo

Returns the version of the shared library for Bloomberg API.
"""
function get_version_info() :: VersionInfo
    major = Ref{Cint}(0)
    minor = Ref{Cint}(0)
    patch = Ref{Cint}(0)
    build = Ref{Cint}(0)
    blpapi_getVersionInfo(major, minor, patch, build)
    return VersionInfo(major[], minor[], patch[], build[])
end

end # module
