
@inline is_service_open(session::Session, service_name::AbstractString) = service_name ∈ session.opened_services
@inline check_service_is_open(session::Session, service_name::AbstractString) = @assert is_service_open(session, service_name) "Service $service_name was not opened in this session."

function Service(session::Session, service_name::AbstractString)
    service_name = service_name_str(service_name)
    check_service_is_open(session, service_name)
    service_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    err = blpapi_Session_getService(session.handle, service_handle_ref, service_name)
    error_check(err, "Failed to get service $service_name.")
    service = Service(service_handle_ref[], String(service_name), session)
    @assert unsafe_string(blpapi_Service_name(service.handle)) == String(service_name)
    return service
end

get_num_operations(service::Service) = Int(blpapi_Service_numOperations(service.handle))

function _get_operation_handle(service::Service, index::Integer) :: Ptr{Cvoid}
    operation_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    err = blpapi_Service_getOperationAt(service.handle, operation_handle_ref, index - 1)
    error_check(err, "Failed to get operation at index $index for service $(service.name).")
    return operation_handle_ref[]
end

# 1 <= index <= get_num_operations(service)
function get_operation(service::Service, index::Integer) :: Operation
    return Operation(_get_operation_handle(service, index))
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

function list_operation_names(service::Service) :: Vector{String}
    num_operations = get_num_operations(service)

    if num_operations == 0
        return Vector{String}()
    else
        operation_names = Vector{String}(undef, num_operations)

        for i in 1:num_operations
            op_handle = _get_operation_handle(service, i)
            ptr_check(op_handle)
            operation_names[i] = unsafe_string(blpapi_Operation_name(op_handle))
        end

        return operation_names
    end
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
