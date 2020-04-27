
SubscriptionList() = SubscriptionList(blpapi_SubscriptionList_create())

function Base.empty!(sublist::SubscriptionList)
    err = blpapi_SubscriptionList_clear(sublist.handle)
    error_check(err, "Failed to clear SubscriptionList")
    nothing
end

function Base.push!(sublist::SubscriptionList, topic::AbstractString) :: SubscriptionTopic
    correlation_id_ref = Ref(CorrelationId())
    err = blpapi_SubscriptionList_addResolved(sublist.handle, topic, correlation_id_ref)
    error_check(err, "Failed to add topic to SubscriptionList")
    return sublist[end]
end

function Base.append!(sublist::SubscriptionList, topics::Vector{T}) :: SubscriptionList where {T<:AbstractString}
    for topic in topics
        push!(sublist, topic)
    end

    return sublist
end

Base.length(sublist::SubscriptionList) = blpapi_SubscriptionList_size(sublist.handle)
Base.isempty(sublist::SubscriptionList) = iszero(length(sublist))
@inline Base.lastindex(sublist::SubscriptionList) = length(sublist)
@inline Base.firstindex(sublist::SubscriptionList) = Cint(1)

@inline function get_topic(sublist::SubscriptionList, index::Integer) :: SubscriptionTopic
    correlation_id_ref = Ref(CorrelationId())
    @assert index > 0 "Invalid index $index."
    err = blpapi_SubscriptionList_correlationIdAt(sublist.handle, correlation_id_ref, index - 1)
    error_check(err, "Failed to get CorrelationId from SubscriptionList at index $index")

    topic_str_ref = Ref{Ptr{UInt8}}(C_NULL)
    err = blpapi_SubscriptionList_topicStringAt(sublist.handle, topic_str_ref, index - 1)
    error_check(err, "Failed to get topic string from SubscriptionList at index $index")

    return SubscriptionTopic(correlation_id_ref[], unsafe_string(topic_str_ref[]))
end

Base.getindex(sublist::SubscriptionList, index::Integer) = get_topic(sublist, index)

function Base.iterate(sublist::SubscriptionList)
    if isempty(sublist)
        return nothing
    else
        return (sublist[1], 2)
    end
end

function Base.iterate(sublist::SubscriptionList, index::Integer)
    if index > length(sublist)
        return nothing
    else
        return (sublist[index], index + 1)
    end
end

function Base.show(io::IO, sublist::SubscriptionList)
    if isempty(sublist)
        print(io, "Empty SubscriptionList")
    else
        println(io, "Subscription List Topics")
        len = length(sublist)
        for (i, topic) in enumerate(sublist)
            if i == len
                print(io, "    $i => $(topic)")
            else
                println(io, "    $i => $(topic)")
            end
        end
    end
end

function subscribe(session::Session, sublist::SubscriptionList) :: SubscriptionList
    err = blpapi_Session_subscribe(session.handle, sublist.handle, C_NULL, Ptr{UInt8}(C_NULL), 0)
    error_check(err, "Failed to subscribe")
    return sublist
end

"""
    subscribe(session::Session, topics) :: SubscriptionList

Subscribes to real-time events on a single topic or a list of topics.
The `topics` argument should be an `AbstractString` or a `Vector{AbstractString}`.

See also [`unsubscribe`](@ref), [`SubscriptionList`](@ref).

# Example

```julia
topic = "//blp/mktdata/ticker/PETR4 BS Equity?fields=BID,ASK"
subscription_list = BLPData.subscribe(session, topic)

i = 1 # event counter
evn = BLPData.try_next_event(session)
while evn != nothing
    println("event \$i")
    println(evn)
    i += 1
    sleep(2) # let's wait for events
    evn = BLPData.try_next_event(session)
end

BLPData.unsubscribe(session, subscription_list)
```
"""
function subscribe(session::Session, topics::Vector{T}) :: SubscriptionList where {T<:AbstractString}
    sublist = SubscriptionList()
    append!(sublist, topics)
    return subscribe(session, sublist)
end

function subscribe(session::Session, topic::AbstractString) :: SubscriptionList
    sublist = SubscriptionList()
    push!(sublist, topic)
    return subscribe(session, sublist)
end

"""
    unsubscribe(session::Session, sublist::SubscriptionList)

Unsubscribes to real-time events on topis in the `sublist`.

See also [`subscribe`](@ref), [`SubscriptionList`](@ref).
"""
function unsubscribe(session::Session, sublist::SubscriptionList)
    err = blpapi_Session_unsubscribe(session.handle, sublist.handle, Ptr{UInt8}(C_NULL), 0)
    error_check(err, "Failed to unsubscribe")
end
