
#
# Session Options
#

function SessionOptions(;
            host::Union{Nothing, S}=nothing,
            port::Union{Nothing, I}=nothing,
            client_mode::Union{Nothing, ClientMode}=nothing,
            service_check_timeout_msecs::Union{Nothing, I2}=nothing,
            service_download_timeout_msecs::Union{Nothing, I3}=nothing
        ) where {S<:AbstractString, I<:Integer, I2<:Integer, I3<:Integer}

    handle = blpapi_SessionOptions_create()
    ptr_check(handle, "Failed to create SessionOptions")

    if host != nothing
        err = blpapi_SessionOptions_setServerHost(handle, host)
        error_check(err)
    end

    if port != nothing
        err = blpapi_SessionOptions_setServerPort(handle, UInt16(port))
        error_check(err)
    end

    if client_mode != nothing
        blpapi_SessionOptions_setClientMode(handle, Int(client_mode))
    end

    if service_check_timeout_msecs != nothing
        err = blpapi_SessionOptions_setServiceCheckTimeout(handle, service_check_timeout_msecs)
        error_check(err)
    end

    if service_download_timeout_msecs != nothing
        err = blpapi_SessionOptions_setServiceDownloadTimeout(handle, service_download_timeout_msecs)
        error_check(err)
    end

    return SessionOptions(handle)
end

get_server_host(opt::SessionOptions) = unsafe_string(blpapi_SessionOptions_serverHost(opt.handle))
get_server_port(opt::SessionOptions) = blpapi_SessionOptions_serverPort(opt.handle)
get_client_mode(opt::SessionOptions) = ClientMode(blpapi_SessionOptions_clientMode(opt.handle))

"""
    Session(services...;
            host=nothing,
            port=nothing,
            client_mode=nothing,
            service_check_timeout_msecs=nothing
        )

Creates a new session for Bloomberg API.

See also [`stop`](@ref), [`ClientMode`](@ref).

# Example

```julia
# starts a session with default parameters:
# * host=127.0.0.1, port=8194
# * client_mode = BLPAPI_CLIENTMODE_AUTO.
session = Blpapi.Session("//blp/mktdata", "//blp/refdata")

# session with customized parameters
customized_session = Blpapi.Session("//blp/refdata",
    host="my_host",
    port=4444,
    client_mode=Blpapi.BLPAPI_CLIENTMODE_DAPI)
```
"""
function Session(services::Set{String};
            host=nothing,
            port=nothing,
            client_mode=nothing,
            service_check_timeout_msecs=nothing,
            service_download_timeout_msecs=nothing
        )

    opt = SessionOptions(host=host, port=port, client_mode=client_mode, service_check_timeout_msecs=service_check_timeout_msecs, service_download_timeout_msecs=service_download_timeout_msecs)
    handle = blpapi_Session_create(opt.handle, C_NULL, C_NULL, C_NULL)
    ptr_check(handle, "Failed to create Session")

    # starts the session
    let
        err = blpapi_Session_start(handle)
        error_check(err, "Failed to start session.")
    end

    opened_services = Set{String}()

    for service_name in services
        @assert isa(service_name, AbstractString)

        # opens the service
        err = blpapi_Session_openService(handle, service_name)
        error_check(err, "Failed to open service $service_name.")

        push!(opened_services, service_name)
    end

    return Session(handle, opened_services)
end

Session(service::AbstractString; host=nothing, port=nothing, client_mode=nothing, service_check_timeout_msecs=nothing, service_download_timeout_msecs=nothing) = Session(Set([String(service)]), host=host, port=port, client_mode=client_mode, service_check_timeout_msecs=service_check_timeout_msecs, service_download_timeout_msecs=service_download_timeout_msecs)
Session(services...; host=nothing, port=nothing, client_mode=nothing, service_check_timeout_msecs=nothing, service_download_timeout_msecs=nothing) = Session(Set([String(service) for service in services]), host=host, port=port, client_mode=client_mode, service_check_timeout_msecs=service_check_timeout_msecs, service_download_timeout_msecs=service_download_timeout_msecs)

"""
    stop(session::Session)

Stops a session.

Once a Session has been stopped
it can only be destroyed.
"""
function stop(session::Session)
    err = blpapi_Session_stop(session.handle)
    error_check(err, "Failed to stop session")
end
