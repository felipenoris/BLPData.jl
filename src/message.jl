
function Element(message::Message)
    element_handle = blpapi_Message_elements(message.handle)
    Element(element_handle, message)
end

function MessageIterator(event::Event)
    return MessageIterator(blpapi_MessageIterator_create(event.handle))
end

function next_message(iter::MessageIterator) :: Union{Nothing, Message}
    result_msg_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    result = blpapi_MessageIterator_next(iter.handle, result_msg_handle_ref)

    if result == 0
        return Message(result_msg_handle_ref[])
    else
        return nothing
    end
end

each_message(event::Event) = MessageIterator(event)

function Base.iterate(iter::MessageIterator, state=nothing)
    iter_result = next_message(iter)
    if iter_result == nothing
        return nothing
    else
        return (iter_result, nothing)
    end
end

@inline function has_correlation_id(message::Message, corr_id::CorrelationId) :: Bool
    return corr_id ∈ message.correlation_ids
end

@inline function check_has_correlation_id(message::Message, corr_id::CorrelationId)
    @assert has_correlation_id(message, corr_id) "Got message with unexpected correlation id: $(message.correlation_ids) (expected $corr_id)."
end
