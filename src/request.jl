
function Request(service::Service, operation_name::AbstractString)
    request_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    err = blpapi_Service_createRequest(service.handle, request_handle_ref, operation_name)
    error_check(err, "Failed to create request")
    return Request(request_handle_ref[], service)
end

function Element(request::Request)
    return Element(blpapi_Request_elements(request.handle), request)
end

function Base.getindex(request::Request, element_name::AbstractString)
    elements = Element(request)
    return elements[element_name]
end

function Base.setindex!(request::Request, val, element_name::AbstractString)
    elements = Element(request)
    elements[element_name] = val
end

function send(request::Request) :: CorrelationId
    correlation_id_ref = Ref(CorrelationId())
    session = request.service.session
    err = blpapi_Session_sendRequest(session.handle, request.handle, correlation_id_ref)
    error_check(err, "Failed to send request")
    return correlation_id_ref[]
end
