
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
List of service names that the default `Session` constructor uses.
See also [`Session`](@ref).

```julia
julia> BLPData.Session()
Session services available: Set(["//blp/refdata", "//blp/mktdata"])

julia> BLPData.DEFAULT_SERVICE_NAMES
Set{String} with 2 elements:
  "//blp/refdata"
  "//blp/mktdata"
```
"""
const DEFAULT_SERVICE_NAMES = Set(["//blp/mktdata", "//blp/refdata"])

"""
List of all serice names based on the BLPAPI documentation.
See also [`Session`](@ref).

```julia
julia> session = BLPData.Session(BLPData.ALL_SERVICE_NAMES)
Session services available: Set(["//blp/mktlist", "//blp/mktdata", "//blp/mktdepthdata", "//blp/instruments", "//blp/pagedata", "//blp/mktvwap", "//blp/mktbar", "//blp/refdata", "//blp/irdctk3", "//blp/tasvc", "//blp/srcref", "//blp/apiflds"])
```
"""
const ALL_SERVICE_NAMES = union(DEFAULT_SERVICE_NAMES, Set([
        "//blp/srcref",
        "//blp/mktvwap",
        "//blp/mktdepthdata",
        "//blp/mktbar",
        "//blp/mktlist",
        "//blp/apiflds",
        "//blp/instruments",
        "//blp/pagedata",
        "//blp/tasvc",
        "//blp/irdctk3"
    ]))

function service_name_str(service_name::AbstractString) :: String
    @assert length(service_name) >= 2 "Short service name `$(service_name)`"

    if !(service_name[1] == '/' && service_name[2] == '/')
        return "//blp/$service_name"
    else
        return String(service_name)
    end
end

const DEFAULT_SESSION_START_TIMEOUT_MSECS = UInt32(5000) # 5 secs

"""
    Session(services;
            host=nothing,
            port=nothing,
            client_mode=nothing,
            service_check_timeout_msecs=nothing
            service_download_timeout_msecs=nothing,
            session_start_timeout_msecs=DEFAULT_SESSION_START_TIMEOUT_MSECS,
            verbose::Bool=false
        )

Creates a new session for Bloomberg API and opens the services listed in the `services` argument.

See also [`stop`](@ref), [`ClientMode`](@ref), [`DEFAULT_SERVICE_NAMES`](@ref), [`ALL_SERVICE_NAMES`](@ref).

# Example

```julia
# starts a session with default parameters:
# * host=127.0.0.1, port=8194
# * client_mode = BLPAPI_CLIENTMODE_AUTO.
# * services = BLPData.DEFAULT_SERVICE_NAMES
session = Blpapi.Session()

# session with customized parameters
customized_session = Blpapi.Session("//blp/refdata",
    host="my_host",
    port=4444,
    client_mode=Blpapi.BLPAPI_CLIENTMODE_DAPI)
```
"""
function Session(services::Set{T}=DEFAULT_SERVICE_NAMES;
            host=nothing,
            port=nothing,
            client_mode=nothing,
            service_check_timeout_msecs=nothing,
            service_download_timeout_msecs=nothing,
            session_start_timeout_msecs=DEFAULT_SESSION_START_TIMEOUT_MSECS,
            verbose::Bool=false
        ) where {T<:AbstractString}

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
        service_name = service_name_str(service_name)

        # opens the service
        err = blpapi_Session_openService(handle, service_name)
        error_check(err, "Failed to open service $service_name.")

        push!(opened_services, service_name)
    end

    return Session(handle, opened_services, session_start_timeout_msecs, verbose)
end

# called by the struct constructor
function handle_session_start_events(session::Session, session_start_timeout_msecs::Integer, verbose::Bool)

    local evn

    try
        evn = next_event(session, timeout_milliseconds=session_start_timeout_msecs)
        @assert evn.event_type == BLPAPI_EVENTTYPE_SESSION_STATUS
        for message in each_message(evn)
            element = Element(message)
            @assert element.name.symbol == :SessionConnectionUp "Failed to start session: expected SessionConnectionUp, got $(element)"
            if verbose
                @info("SessionConnectionUp: server=$(element["server"]), encryptionStatus=$(element["encryptionStatus"])")
            end
        end
    finally
        # destroy this event early, before GC
        isa(evn, Event) && destroy!(evn)
    end

    try
        evn = next_event(session, timeout_milliseconds=session_start_timeout_msecs)
        @assert evn.event_type == BLPAPI_EVENTTYPE_SESSION_STATUS
        for message in each_message(evn)
            element = Element(message)
            @assert element.name.symbol == :SessionStarted "Failed to start session: expected SessionStarted, got $(element)"
            if verbose
                @info(element)
            end
        end
    finally
        # destroy this event early, before GC
        isa(evn, Event) && destroy!(evn)
    end

    # handle one ServiceOpened event for each opened service
    if !isempty(session.opened_services)
        for i in 1:length(session.opened_services)
            try
                evn = next_event(session, timeout_milliseconds=session_start_timeout_msecs)
                @assert evn.event_type == BLPAPI_EVENTTYPE_SERVICE_STATUS
                for message in each_message(evn)
                    element = Element(message)
                    @assert element.name.symbol == :ServiceOpened "Failed to start session: expected ServiceOpened, got $(element)"
                    if verbose
                        @info(element)
                    end
                end
            finally
                # destroy this event early, before GC
                isa(evn, Event) && destroy!(evn)
            end
        end
    end

    evn = try_next_event(session)
    if evn != nothing
        @warn("Unhandled event during Session opening: $evn.")
        destroy!(evn)
    end
end

function Session(service::AbstractString;
            host=nothing,
            port=nothing,
            client_mode=nothing,
            service_check_timeout_msecs=nothing,
            service_download_timeout_msecs=nothing,
            session_start_timeout_msecs=DEFAULT_SESSION_START_TIMEOUT_MSECS,
            verbose::Bool=false
        )

    Session(Set([String(service)]),
            host=host,
            port=port,
            client_mode=client_mode,
            service_check_timeout_msecs=service_check_timeout_msecs,
            service_download_timeout_msecs=service_download_timeout_msecs,
            session_start_timeout_msecs=session_start_timeout_msecs,
            verbose=verbose)
end

function Session(services::Vector{T};
            host=nothing,
            port=nothing,
            client_mode=nothing,
            service_check_timeout_msecs=nothing,
            service_download_timeout_msecs=nothing,
            session_start_timeout_msecs=DEFAULT_SESSION_START_TIMEOUT_MSECS,
            verbose::Bool=false
        ) where {T<:AbstractString}

    Session(Set(services),
            host=host,
            port=port,
            client_mode=client_mode,
            service_check_timeout_msecs=service_check_timeout_msecs,
            service_download_timeout_msecs=service_download_timeout_msecs,
            session_start_timeout_msecs=session_start_timeout_msecs,
            verbose=verbose)
end

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

"""
    next_event(event_source; timeout_milliseconds::Integer=UInt32(0)) :: Event

Reads the next event in the stream events of the `event_source`.
This method blocks until an event is available.

See also [`try_next_event`](@ref).

# Event Sources

The `event_source` can be either a `Session` or an `EventQueue`.
"""
function next_event(session::Session; timeout_milliseconds::Integer=UInt32(0)) :: Event
    event_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    err = blpapi_Session_nextEvent(session.handle, event_handle_ref, timeout_milliseconds)
    error_check(err, "Failed to get next event from session")
    return Event(event_handle_ref[], session)
end

"""
    try_next_event(event_source) :: Union{Nothing, Event}

Reads the next event in the stream events of the `event_source`.
If no event is available, returns `nothing`. This method never blocks.

See also [`next_event`](@ref).

# Event Sources

The `event_source` can be either a `Session` or an `EventQueue`.
"""
function try_next_event(session::Session) :: Union{Nothing, Event}
    event_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    status = blpapi_Session_tryNextEvent(session.handle, event_handle_ref)
    if status == 0
        return Event(event_handle_ref[], session)
    else
        return nothing
    end
end

Base.getindex(session::Session, service_name::AbstractString) = Service(session, service_name)

"""
    get_opened_services_names(session::Session) :: Set{String}

Returns the set of names for opened services for this `session`.
"""
function get_opened_services_names(session::Session) :: Set{String}
    return deepcopy(session.opened_services)
end

"""
    is_service_open(session::Session, service_name::AbstractString) :: Bool

Returns `true` if `service_name` is opened in the `session`.
"""
@inline function is_service_open(session::Session, service_name::AbstractString) :: Bool
    return service_name_str(service_name) ∈ session.opened_services
end

@inline function check_service_is_open(session::Session, service_name::AbstractString)
    @assert is_service_open(session, service_name) "Service $service_name was not opened in this session."
end
