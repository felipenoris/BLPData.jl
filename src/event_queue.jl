
"""
    purge(queue::EventQueue)

Purges `Event`s in the queue which have not been processed
and cancel any pending requests.

The `queue` can be subsequently re-used by another request.
"""
function purge(queue::EventQueue)
    err = blpapi_EventQueue_purge(queue.handle)
    error_check(err, "Failed to purge EventQueue")
    nothing
end

EventQueue() = EventQueue(blpapi_EventQueue_create())

"""
    next_event(queue::EventQueue; timeout_milliseconds::Integer=Cint(0)) :: Event

Returns the next event available in the `queue`.
If `timeout_milliseconds` is zero, waits forever until an event is available.
"""
function next_event(queue::EventQueue; timeout_milliseconds::Integer=Cint(0)) :: Event
    event_handle = blpapi_EventQueue_nextEvent(queue.handle, timeout_milliseconds)
    return Event(event_handle, queue)
end

function try_next_event(queue::EventQueue) :: Union{Nothing, Event}
    event_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    status = blpapi_EventQueue_tryNextEvent(queue.handle, event_handle_ref)
    if status == 0
        return Event(event_handle_ref[], queue)
    else
        return nothing
    end
end
