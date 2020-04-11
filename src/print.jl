
function sep(io::IO)
    println(io, "-----------------------")
    println(io, "")
end

function Base.show(io::IO, op::Operation)
    println(io, "Operation: $(op.name)")
    sep(io)
    println(io, "Request Definition")
    show(io, op.request_definition)
    sep(io)
    if isempty(op.response_definitions)
        println(io, "Response Definition is empty")
    else
        num_response_definitions = length(op.response_definitions)
        for (i, resp_def) in enumerate(op.response_definitions)
            println(io, "Response Definition $i of $num_response_definitions:")
            show(io, resp_def)
        end
    end

    sep(io)
end

function Base.show(io::IO, def::SchemaElementDefinition)
    println(io, "Schema Element: $(def.name); status $(def.status)")
    println(io, "Min Values: $(def.min_values); Max Values: $(def.max_values)")

    if !isempty(def.alternate_names)
        println(io, "Alternate Names: $(join(def.alternate_names, ", "))")
    end

    show(io, def.schema_type)
end

Base.show(io::IO, blpname::BLPName) = show(io, blpname.symbol)

function _show_simple_schema(io::IO, @nospecialize(schema))
    println(io, "Schema Type $(schema.name) - $(schema.description) - $(schema.status) - $(schema.datatype)")
end

function Base.show(io::IO, schema_type::SimpleSchemaTypeDefinition)
    _show_simple_schema(io, schema_type)
end

function Base.show(io::IO, schema_type::ComplexSchemaTypeDefinition)
    _show_simple_schema(io, schema_type)

    if !isempty(schema_type.elements)
        num_elements = length(schema_type.elements)

        for (i, element_definition) in enumerate(schema_type.elements)
            println(io, "$(schema_type.name) element $(i) of $num_elements:")
            show(io, element_definition)
        end
    end
end

function Base.show(io::IO, schema_type::EnumerationSchemaTypeDefinition)
    _show_simple_schema(io, schema_type)
    show(io, schema_type.enumeration)
end

function Base.show(io::IO, list::BLPConstantList)
    println(io, "Enumeration $(list.name) - $(list.description) - $(list.status) - $(list.datatype)")
    if isempty(list.list)
        println(io, "Enumeration is empty")
    else
        num_elements = length(list.list)

        for (i, blp_constant) in enumerate(list.list)
            println(io, "$(list.name) value $(i) of $num_elements:")
            show(io, blp_constant)
        end
    end
end

function Base.show(io::IO, blp_const::BLPConstant)
    println(io, "$(blp_const.name) - $(blp_const.description) - $(blp_const.status) - $(blp_const.datatype). Julia Value: $(blp_const.value)")
end

function Base.show(io::IO, element::Element{D, false, T}) where {D, T}
    print(io, "Element $(element.name) <: $(element.datatype)")
end

function Base.show(io::IO, element::Element{D, true, T}) where {D, T}
    print(io, "Element $(element.name) <: Vector{$(element.datatype)}")
end
