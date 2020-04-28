
module BLPData

using Dates
using Printf

include("deps.jl")
include("types.jl")
include("correlation_id.jl")
include("datetime.jl")
include("c.jl")
include("constant.jl")
include("blpname.jl")
include("session.jl")
include("service.jl")
include("schema.jl")
include("element.jl")
include("request.jl")
include("message.jl")
include("event_queue.jl")
include("print.jl")
include("bdh.jl")
include("bdh_intraday_ticks.jl")
include("bds.jl")
include("bdp.jl")
include("subscription.jl")

function __init__()
    check_deps()
end

@inline function error_check(code::Cint)
    if code != 0
        error(blpapi_getLastErrorDescription(code))
    end

    nothing
end

@inline function error_check(code::Cint, ctx_msg::AbstractString)
    if code != 0
        error("$ctx_msg: $(blpapi_getLastErrorDescription(code))")
    end

    nothing
end

@inline function ptr_check(ptr::Ptr{Cvoid})
    if ptr == C_NULL
        error("Got a NULL pointer.")
    end

    nothing
end

@inline function ptr_check(ptr::Ptr{Cvoid}, ctx_msg::AbstractString)
    if ptr == C_NULL
        error("$ctx_msg: got a NULL pointer.")
    end

    nothing
end

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
