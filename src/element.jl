
blp_date_string(date::Date) :: String = Dates.format(date, dateformat"yyyymmdd")
blpstring(str::AbstractString) = str
blpstring(date::Date) = blp_date_string(date)

function SchemaElementDefinition(element::Element)
    return SchemaElementDefinition(blpapi_Element_definition(element.handle))
end

function is_array(::Type{Element{A,D}}) :: Bool where {A,D}
    A
end

function is_array(::Element{A,D}) :: Bool where {A,D}
    A
end

@generated function get_child_element(element::AbstractElement{A,D}, index) where {A,D}
    if is_complex_datatype(D)

        @assert !A "get_child_element not allowed for array element."

        if index <: Integer
            # index into element using an Integer as key
            return quote
                result_element_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
                err = blpapi_Element_getElementAt(element.handle, result_element_handle_ref, index - 1)
                error_check(err, "Failed to get element at index $index from $(element.name)")
                return Element(result_element_handle_ref[], element)
            end

        elseif index <: AbstractString
            # index into element using a String as key
            return quote
                result_element_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
                err = blpapi_Element_getElement(element.handle, result_element_handle_ref, pointer(index), C_NULL)
                error_check(err, "Failed to get element $index from $(element.name)")
                return Element(result_element_handle_ref[], element)
            end
        else
            error("index data type $index not supported")
        end
    end

    error("get_child_element not allowed for data type $D.")
end

@generated function Base.getindex(element::AbstractElement{false,D}, index::AbstractString) where {D}

    # index <: AbstractString
    # used to index into child elements of a complex element that is not an array
    if is_complex_datatype(D)
        return quote
            return get_child_element(element, index)
        end
    end

    error("Base.getindex not implemented for element with datatype $D with is_array = $A.")
end

has_name(element::Element, name) = has_name(element.name, name)

function get_choice(element::AbstractElement{false,BLPAPI_DATATYPE_CHOICE})
    result_element_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
    err = blpapi_Element_getChoice(element.handle, result_element_handle_ref)
    error_check(err, "Failed to get choice from $(element.name)")
    return Element(result_element_handle_ref[], element)
end

Base.getindex(element::AbstractElement{false,BLPAPI_DATATYPE_CHOICE}) = get_choice(element)

@generated function Base.haskey(element::AbstractElement{false,D}, name::AbstractString) :: Bool where {D}
    if is_complex_datatype(D)
        return quote
            return blpapi_Element_hasElement(element.handle, pointer(name), C_NULL) != 0
        end
    end

    error("Base.haskey not implemented for element with datatype $D.")
end

@generated function Base.push!(element::Element{true,D}, val::V) where {D,V}
    if D == BLPAPI_DATATYPE_STRING
        return quote
            err = blpapi_Element_setValueString(element.handle, blpstring(val), BLPAPI_ELEMENT_INDEX_END)
            error_check(err, "Failed to push value $val to element $(element.name)")
        end
    end

    error("push! not implemented for datatype $D.")
end

function Base.push!(element::Element, vals...)
    for val in vals
        push!(element, val)
    end
end

Base.append!(element::Element{true}, vals::Vector) = push!(element, vals...)

# allows `element[] = val`, when element is not an array
@generated function Base.setindex!(element::Element{false,D}, val::V) where {D,V}
    if D == BLPAPI_DATATYPE_STRING
        return quote
            err = blpapi_Element_setValueString(element.handle, blpstring(val), 0)
            error_check(err, "Failed to push value $val to element $(element.name)")
        end

    elseif D == BLPAPI_DATATYPE_BOOL
        @assert val == Bool "Can't set value of type $val to element of type $D."
        return quote
            err = blpapi_Element_setValueBool(element.handle, val, 0)
            error_check(err, "Failed to push value $val to element $(element.name)")
        end

    elseif D == BLPAPI_DATATYPE_ENUMERATION
        # for enums, we need to check the value type informed by the element's schema
        # and also if the value is allowed for the field
        return quote
            schema = SchemaElementDefinition(element)
            schema_type = schema.schema_type
            @assert isa(schema_type, EnumerationSchemaTypeDefinition)

            if schema_type.enumeration.datatype == BLPAPI_DATATYPE_STRING
                val_str = blpstring(val)
                @assert is_value_allowed(element, val_str) "Unvalid value for enum `$(element.name)`: `$val_str`. Options are: $(list_enum_options(element))"

                err = blpapi_Element_setValueString(element.handle, val_str, 0)
                error_check(err, "Failed to push value $val_str to element $(element.name)")
            end
        end
    end

    error("setindex! not implemented for datatype $D.")
end

function is_value_allowed(element::Element{false,BLPAPI_DATATYPE_ENUMERATION}, val)
    schema = SchemaElementDefinition(element)
    schema_type = schema.schema_type
    @assert isa(schema_type, EnumerationSchemaTypeDefinition)

    # check wether val is allowed for this enum
    val_is_allowed = false
    for enum_const in schema_type.enumeration.list
        if enum_const.value == val
            val_is_allowed = true
            break
        end
    end

    return val_is_allowed
end

function list_enum_options(element::Element{false, BLPAPI_DATATYPE_ENUMERATION})
    schema = SchemaElementDefinition(element)
    schema_type = schema.schema_type
    @assert isa(schema_type, EnumerationSchemaTypeDefinition)
    return [ enum_const.value for enum_const in schema_type.enumeration.list ]
end

# allows `element["child_element_name"] = val`, when element is complex and not an array
@generated function Base.setindex!(element::Element{false,D}, val::V, name::AbstractString) where {D,V}
    if is_complex_datatype(D)
        return quote
            child_element = element[name]
            child_element[] = val
            nothing
        end
    end
end

struct ChildElementsIterator{T<:AbstractElement{false,BLPAPI_DATATYPE_SEQUENCE}}
    element::T
    num_elements::Csize_t
end

function each_child_element(element::T) where {T<:AbstractElement{false,BLPAPI_DATATYPE_SEQUENCE}}
    ChildElementsIterator(element, blpapi_Element_numElements(element.handle))
end

Base.isempty(itr::ChildElementsIterator) = itr.num_elements == 0
Base.length(itr::ChildElementsIterator) = itr.num_elements

function Base.iterate(itr::ChildElementsIterator)
    if isempty(itr)
        return nothing
    else
        # (current_element, next_index)
        return (get_child_element(itr.element, UInt64(1)), UInt64(2))
    end
end

function Base.iterate(itr::ChildElementsIterator, state::UInt64)
    if state > itr.num_elements
        return nothing
    else
        return (get_child_element(itr.element, state), state + UInt64(1))
    end
end

"""
    get_element_value(element, [index])

Returns the Julia value for `element`.

`element` cannot be a `BLPAPI_DATATYPE_SEQUENCE` or `BLPAPI_DATATYPE_CHOICE`.
"""
@generated function get_element_value(element::AbstractElement{A,D}) where {A,D}
    if A
        # retrieves a vector
        return quote
            num_values = blpapi_Element_numValues(element.handle)

            result = Vector()
            for i in 1:num_values
                push!(result, get_element_value(element, i))
            end

            return result
        end
    else
        if is_complex_datatype(D)
            error("get_element_value: Can't get element value from a complex element that is not an array.")
        end

        # retrieves a scalar
        return quote
            return get_element_value(element, 1)
        end
    end
end

@generated function get_element_value(element::AbstractElement{A,D}, index::Integer) where {A,D}
    if D == BLPAPI_DATATYPE_BOOL
        parse_value_block = quote
            buffer_ref = Ref{Cint}()
            err = blpapi_Element_getValueAsBool(element.handle, buffer_ref, index-1)
            error_check(err, "Failed to get Bool element value")
            return buffer_ref[] != 0
        end

    elseif D == BLPAPI_DATATYPE_CHAR
        parse_value_block = quote
            buffer_ref = Ref{Cchar}()
            err = blpapi_Element_getValueAsChar(element.handle, buffer_ref, index-1)
            error_check(err, "Failed to get Char element value")
            return Char(buffer_ref[])
        end

    elseif D == BLPAPI_DATATYPE_INT32
        parse_value_block = quote
            buffer_ref = Ref{Int32}()
            err = blpapi_Element_getValueAsInt32(element.handle, buffer_ref, index-1)
            error_check(err, "Failed to get Int32 element value")
            return buffer_ref[]
        end

    elseif D == BLPAPI_DATATYPE_INT64
        parse_value_block = quote
            buffer_ref = Ref{Int64}()
            err = blpapi_Element_getValueAsInt64(element.handle, buffer_ref, index-1)
            error_check(err, "Failed to get Int32 element value")
            return buffer_ref[]
        end

    elseif D == BLPAPI_DATATYPE_FLOAT32
        parse_value_block = quote
            buffer_ref = Ref{Float32}()
            err = blpapi_Element_getValueAsFloat32(element.handle, buffer_ref, index-1)
            error_check(err, "Failed to get Float32 element value")
            return buffer_ref[]
        end

    elseif D == BLPAPI_DATATYPE_FLOAT64
        parse_value_block = quote
            buffer_ref = Ref{Float64}()
            err = blpapi_Element_getValueAsFloat64(element.handle, buffer_ref, index-1)
            error_check(err, "Failed to get Float64 element value")
            return buffer_ref[]
        end

    elseif D == BLPAPI_DATATYPE_STRING
        parse_value_block = quote
            buffer_ref = Ref{Cstring}()
            err = blpapi_Element_getValueAsString(element.handle, buffer_ref, index-1)
            error_check(err, "Failed to get String element value")
            return unsafe_string(buffer_ref[])
        end

    elseif D == BLPAPI_DATATYPE_DATE
        parse_value_block = quote
            buffer_ref = Ref{BLPDateTime}()
            err = blpapi_Element_getValueAsDatetime(element.handle, buffer_ref, index-1)
            error_check(err, "Failed to get Date element value")
            return Dates.Date(buffer_ref[])
        end

    elseif D == BLPAPI_DATATYPE_DATETIME
        parse_value_block = quote
            buffer_ref = Ref{BLPDateTime}()
            err = blpapi_Element_getValueAsDatetime(element.handle, buffer_ref, index-1)
            error_check(err, "Failed to get Date element value")
            #return DateTime(buffer_ref[]) # TODO: use TimeZones.
            return buffer_ref[]
        end

    elseif D == BLPAPI_DATATYPE_SEQUENCE
        # get_element_value can be used on sequence only if it is an array
        @assert A "get_element_value: Can't get element value from datatype $D with is_array = $A."

        parse_value_block = quote
            buffer_ref = Ref{Ptr{Cvoid}}(C_NULL)
            err = blpapi_Element_getValueAsElement(element.handle, buffer_ref, index-1)
            error_check(err, "Failed to get Date element value")
            return Element(buffer_ref[], element)
        end
    else
        error("get_element_value: support for datatype $D not implemented.")
    end

    return quote
        if is_null_element(element)
            return missing
        else
            $parse_value_block
        end
    end
end

function is_null_value(element::AbstractElement, index::Integer)
    rc = blpapi_Element_isNullValue(element.handle, index-1)

    if rc != 0 && rc != 1
        error("Unexpected result of blpapi_Element_isNullValue on element of type $(typeof(element)): $rc")
    end

    return rc != 0
end

function is_null_element(element::AbstractElement)
    rc = blpapi_Element_isNull(element.handle)
    return rc != 0
end
