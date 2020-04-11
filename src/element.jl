
blp_date_string(date::Date) :: String = Dates.format(date, dateformat"yyyymmdd")
blpstring(str::AbstractString) = str
blpstring(date::Date) = blp_date_string(date)

function SchemaElementDefinition(element::Element)
    return SchemaElementDefinition(blpapi_Element_definition(element.handle))
end

@generated function Base.getindex(element::AbstractElement{D}, name::AbstractString) where {D}
    if is_complex_datatype(D)
        return quote
            result_element_handle_ref = Ref{Ptr{Cvoid}}(C_NULL)
            err = blpapi_Element_getElement(element.handle, result_element_handle_ref, pointer(name), C_NULL)
            error_check(err, "Failed to get element $name from $(element.name)")
            return Element(result_element_handle_ref[], element)
        end
    end

    error("Base.getindex not implemented for element with datatype $D.")
end

@generated function Base.push!(element::Element{D,true,T}, val::V) where {D,T,V}
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

@generated function Base.setindex!(element::Element{D,false,T}, val::V) where {D,T,V}
    if D == BLPAPI_DATATYPE_STRING
        return quote
            err = blpapi_Element_setValueString(element.handle, blpstring(val), 0)
            error_check(err, "Failed to push value $val to element $(element.name)")
        end
    end

    error("setindex! not implemented for datatype $D.")
end

@generated function Base.setindex!(element::Element{D,false,T}, val::V, name::AbstractString) where {D,T,V}
    if is_complex_datatype(D)
        return quote
            child_element = element[name]
            child_element[] = val
            nothing
        end
    end
end
