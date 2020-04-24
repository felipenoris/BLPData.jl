
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

function send_request(request::Request, queue::EventQueue=EventQueue()) :: Tuple{EventQueue, CorrelationId}
    correlation_id_ref = Ref(CorrelationId())
    session = request.service.session
    err = blpapi_Session_sendRequest(session.handle, request.handle, correlation_id_ref, queue.handle)
    error_check(err, "Failed to send request")
    return queue, correlation_id_ref[]
end

function send_request(f::Function, session::Session, service_name::AbstractString, operation_name::AbstractString, queue::EventQueue=EventQueue()) :: Tuple{EventQueue, CorrelationId}
    request = Request(session, service_name, operation_name)

    # inspect result schema
    # elements = Element(req)
    # elements_schema = SchemaElementDefinition(elements)

    f(request)
    return send_request(request, queue)
end

function for_each_response_message_element(f::Function, queue::EventQueue, corr_id::CorrelationId; timeout_milliseconds::Integer=UInt32(0), verbose::Bool=false)

    local response_event::Event
    local yielded = false # marks wether previous try_next_event call didn't return an event, causing a yield() call

    while true

        if yielded
            verbose && println("started next_event on corr_id=$corr_id...")
            response_event = next_event(queue, timeout_milliseconds=timeout_milliseconds)
            verbose && println("... finished next_event on corr_id=$corr_id.")
            yielded = false # resets flag
        else
            try_next_event_result = try_next_event(queue)

            if try_next_event_result == nothing
                yielded = true
                yield()
                continue
            else
                response_event = try_next_event_result
            end
        end

        if response_event.event_type == BLPAPI_EVENTTYPE_TIMEOUT
            error("Response Timeout.")

        elseif response_event.event_type == BLPAPI_EVENTTYPE_REQUEST_STATUS
            error("Request Error: $response_event.")
        end

        @assert response_event.event_type == BLPAPI_EVENTTYPE_RESPONSE || response_event.event_type == BLPAPI_EVENTTYPE_PARTIAL_RESPONSE "Tried to handle non-response event of type $(response_event.event_type)."

        # process BLPAPI_EVENTTYPE_RESPONSE or BLPAPI_EVENTTYPE_PARTIAL_RESPONSE
        verbose && @info("Reading messages from event $(response_event.event_type)")
        for message in each_message(response_event)
            @assert corr_id ∈ message.correlation_ids "Got message with unexpected correlation id: $(message.correlation_ids) (expected $corr_id)."
            element = Element(message)

            if verbose
                println("Reponse Element Schema")
                println(SchemaElementDefinition(element))
            end

            f(Element(message))
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
    parse_response_as(::Type{T}, queue::EventQueue, corr_id::CorrelationId; timeout_milliseconds::Integer=UInt32(0), verbose::Bool=false) :: Vector{T} where {T}

Parses all response messages as `Vector{T}`, applying `T(element)` for each `element` read from the response.
"""
function parse_response_as(::Type{T}, queue::EventQueue, corr_id::CorrelationId; timeout_milliseconds::Integer=UInt32(0), verbose::Bool=false) where {T}
    result = Vector{T}()
    for_each_response_message_element(queue, corr_id; timeout_milliseconds=timeout_milliseconds, verbose=verbose) do element
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
