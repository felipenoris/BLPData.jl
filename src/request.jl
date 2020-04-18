
function Request(service::Service, operation_name::AbstractString)
    request_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    err = blpapi_Service_createRequest(service.handle, request_handle_ref, operation_name)
    error_check(err, "Failed to create request")
    return Request(request_handle_ref[], service)
end

Request(session::Session, service_name::AbstractString, operation_name::AbstractString) = Request(Service(session, service_name), operation_name)

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

function send_request(request::Request) :: CorrelationId
    correlation_id_ref = Ref(CorrelationId())
    session = request.service.session
    err = blpapi_Session_sendRequest(session.handle, request.handle, correlation_id_ref)
    error_check(err, "Failed to send request")
    return correlation_id_ref[]
end

function send_request(f::Function, session::Session, service_name::AbstractString, operation_name::AbstractString) :: CorrelationId
    request = Request(session, service_name, operation_name)

    # inspect result schema
    # elements = Element(req)
    # elements_schema = BLP.SchemaElementDefinition(elements)

    f(request)
    return send_request(request)
end

function for_each_response_message_element(f::Function, session::Session, corr_id::CorrelationId; timeout_milliseconds::Integer=UInt32(0), verbose::Bool=false)
    while true
        response_event = next_event(session, timeout_milliseconds=timeout_milliseconds)

        if response_event.event_type == BLPAPI_EVENTTYPE_TIMEOUT
            error("Response Timeout.")

        elseif response_event.event_type != BLPAPI_EVENTTYPE_RESPONSE && response_event.event_type != BLPAPI_EVENTTYPE_PARTIAL_RESPONSE
            verbose && @warn("Ignoring response event $(response_event.event_type)")
            continue
        end

        # process BLPAPI_EVENTTYPE_RESPONSE or BLPAPI_EVENTTYPE_PARTIAL_RESPONSE
        verbose && @info("Reading messages from event $(response_event.event_type)")
        for message in each_message(response_event)
            if corr_id ∈ message.correlation_ids
                element = Element(message)

                if verbose
                    println("Reponse Element Schema")
                    println(BLP.SchemaElementDefinition(element))
                end

                f(Element(message))

            else
                error("Got message with unexpected correlation id: $corr_id: $message.")
            end
        end

        # check if response is complete
        if response_event.event_type == BLPAPI_EVENTTYPE_RESPONSE
            verbose && @info("Finished reading events")
            break
        end
    end

    nothing
end

"""
    parse_response_as(::Type{T}, session::Session, corr_id::CorrelationId; timeout_milliseconds::Integer=UInt32(0), verbose::Bool=false) :: Vector{T} where {T}

Parses all response messages as `Vector{T}`, applying `T(element)` for each `element` read from the response.
"""
function parse_response_as(::Type{T}, session::Session, corr_id::CorrelationId; timeout_milliseconds::Integer=UInt32(0), verbose::Bool=false) where {T}
    result = Vector{T}()
    for_each_response_message_element(session, corr_id; timeout_milliseconds=timeout_milliseconds, verbose=verbose) do element
        push!(result, T(element))
    end
    return result
end

function push_named_tuples!(result::T, element_vec::Element{true, BLPAPI_DATATYPE_SEQUENCE}) where {T<:Vector}
    tuple_keys = nothing

    for element in get_element_value(element_vec)

        if tuple_keys == nothing
            tuple_keys = Tuple([ child_element.name.symbol for child_element in each_child_element(element) ])
        else
            @assert tuple_keys == Tuple([ child_element.name.symbol for child_element in each_child_element(element) ])
        end

        tuple_values = Tuple([ get_element_value(child_element) for child_element in each_child_element(element) ])
        push!(result, (; zip(tuple_keys, tuple_values)...)) # trick based on the docstring for NamedTuple
    end
end
