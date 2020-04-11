
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

function Service(session::Session, service_name::AbstractString)
    @assert service_name ∈ session.opened_services "Service $service_name was not opened in this session."
    service_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    err = blpapi_Session_getService(session.handle, service_handle_ref, service_name)
    error_check(err, "Failed to get service $service_name.")
    service = Service(service_handle_ref[], String(service_name), session)
    @assert unsafe_string(blpapi_Service_name(service.handle)) == String(service_name)
    return service
end

get_num_operations(service::Service) = Int(blpapi_Service_numOperations(service.handle))

# 1 <= index <= get_num_operations(service)
function get_operation(service::Service, index::Integer) :: Operation
    operation_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    err = blpapi_Service_getOperationAt(service.handle, operation_handle_ref, index - 1)
    error_check(err, "Failed to get operation at index $index for service $(service.name).")
    return Operation(operation_handle_ref[])
end

function get_operation(service::Service, name::AbstractString) :: Operation
    operation_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    err = blpapi_Service_getOperation(service.handle, operation_handle_ref, name, C_NULL)
    error_check(err, "Failed to get operation $name from $(service.name).")
    return Operation(operation_handle_ref[])
end

function has_operation(service::Service, name::AbstractString) :: Bool
    operation_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    err = blpapi_Service_getOperation(service.handle, operation_handle_ref, name, C_NULL)
    return err == 0
end

function Operation(op_handle::Ptr{Cvoid})

    ptr_check(op_handle, "Failed to create Operation")

    function _request_definition(op_handle::Ptr{Cvoid})
        request_definition_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
        err = blpapi_Operation_requestDefinition(op_handle, request_definition_handle_ref)
        error_check(err, "Failed to get request definition from operation $(unsafe_string(blpapi_Operation_name(op_handle))).")
        return SchemaElementDefinition(request_definition_handle_ref[])
    end

    function _response_definitions(op_handle::Ptr{Cvoid}) :: Vector{AbstractSchemaElementDefinition}
        num_response_definitions = blpapi_Operation_numResponseDefinitions(op_handle)

        if num_response_definitions == 0
            return Vector{AbstractSchemaElementDefinition}()
        else
            @assert num_response_definitions > 0 "Failed to get response definitions from operation $(unsafe_string(blpapi_Operation_name(op_handle)))."
            defs = Vector{AbstractSchemaElementDefinition}(undef, num_response_definitions)

            for i in 1:num_response_definitions
                el_def_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
                err = blpapi_Operation_responseDefinition(op_handle, el_def_handle_ref, i-1)
                error_check(err, "Failed to get response definition $i from operation $(unsafe_string(blpapi_Operation_name(op_handle)))")
                defs[i] = SchemaElementDefinition(el_def_handle_ref[])
            end

            return defs
        end
    end

    return Operation(
            unsafe_string(blpapi_Operation_name(op_handle)),
            _request_definition(op_handle),
            _response_definitions(op_handle)
        )
end
