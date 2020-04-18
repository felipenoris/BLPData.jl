
function Base.show(io::IO, s::Session)
    print(io, "Session services available: $(s.opened_services)")
end

function Base.show(io::IO, s::Service)
    print(io, "Service(\"$(s.name)\")")
end

# Operation is always top level
function Base.show(io::IO, op::Operation)
    println(io, "Operation: $(op.name)")
    println(io)
    println(io, "Request Definition")
    sep(io)
    show(io, op.request_definition)
    println(io)
    if isempty(op.response_definitions)
        println(io, "Response Definition is empty")
    else
        num_response_definitions = length(op.response_definitions)
        for (i, resp_def) in enumerate(op.response_definitions)
            println(io, "Response Definition $i of $num_response_definitions:")
            sep(io)
            show(io, resp_def)
            println(io)
        end
    end
end

Base.show(io::IO, schema::SchemaElementDefinition) = print_schema_tree(io, schema)
Base.show(io::IO, schema_type::AbstractSchemaTypeDefinition) = print_schema_tree(io, schema_type)

function print_schema_tree(io::IO, schema::SchemaElementDefinition, prefix="")
    print(io, "$(prefix)Schema Element `$(schema.name)` - $(schema.status) - ")
    print(io, "Values $(schema.min_values)..")
    if schema.max_values == typemax(schema.max_values)
        print(io, "Unbounded")
    else
        print(io, "$(schema.max_values)")
    end
    println(io)

    if !isempty(schema.alternate_names)
        println(io, "Alternate Names: $(join(schema.alternate_names, ", "))")
    end

    print_schema_tree(io, schema.schema_type, prefix)
end

function print_schema_tree(io::IO, schema::SimpleSchemaTypeDefinition, prefix="")
    println(io, "$(prefix)Simple Schema Type `$(schema.name)` - $(schema.description) - $(schema.status) <: $(schema.datatype)")
end

function print_schema_tree(io::IO, schema::ComplexSchemaTypeDefinition, prefix="")
    println(io, "$(prefix)Complex Schema Type `$(schema.name)` - $(schema.description) - $(schema.status) <: $(schema.datatype)")

    if isempty(schema.elements)
        println(io, "$(prefix)Empty.")
    else
        num_elements = length(schema.elements)
        for (i, element_def) in enumerate(schema.elements)
            println(io, "$(prefix)$(schema.name) element $(i) of $num_elements:")
            print_schema_tree(io::IO, element_def, "    $prefix")
        end
    end
end

function print_schema_tree(io::IO, schema::EnumerationSchemaTypeDefinition, prefix="")
    println(io, "$(prefix)Enumeration Schema Type `$(schema.name)` - $(schema.description) - $(schema.status) <: $(schema.datatype)")
    print_schema_tree(io, schema.enumeration, "    $prefix")
end

function sep(io::IO)
    println(io, "--------------------------")
    println(io)
end

Base.show(io::IO, blpname::BLPName) = print(io, "BLPName(\"$(blpname.symbol)\")")

function print_schema_tree(io::IO, list::BLPConstantList, prefix="")
    println(io, "$(prefix)Enumeration $(list.name) - $(list.description) - $(list.status) - $(list.datatype)")
    if isempty(list.list)
        println(io, "$(prefix)Enumeration is empty")
    else
        num_elements = length(list.list)

        for (i, blp_constant) in enumerate(list.list)
            print(io, "$(prefix)$(list.name) value $(i) of $num_elements: ")
            show(io, blp_constant)
            println(io)
        end
    end
end

function Base.show(io::IO, blp_const::BLPConstant)
    print(io, "$(blp_const.name) - $(blp_const.description) - $(blp_const.status) - $(blp_const.datatype). Julia Value: `$(blp_const.value)`.")
end

Base.show(io::IO, el::Element) = print_element_tree(io, el)

function print_element_tree(io::IO, root::Element{A,D}, prefix="") where {A,D}
    new_prefix = "    " * prefix

    if is_choice_datatype(D)
        println(io, "$prefix$(root.name) <: Element{$A, $D}")
        print_element_tree(io, get_choice(root), new_prefix)
    elseif D == BLPAPI_DATATYPE_SEQUENCE

        println(io, "$prefix$(root.name) <: Element{$A, $D}")

        if A # vector of sequences
            vector = get_element_value(root)
            for element in vector
                print_element_tree(io, element, new_prefix)
            end
        else
            # single sequence
            for child in each_child_element(root)
                print_element_tree(io, child, new_prefix)
            end
        end
    else
        @assert is_simple_datatype(D)
        println(io, "$prefix$(root.name) <: Element{$A, $D} = $(get_element_value(root))")
    end
end
