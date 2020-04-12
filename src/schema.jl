
function is_complex_datatype(datatype::BLPDataType) :: Bool
    return (
            datatype == BLPAPI_DATATYPE_SEQUENCE ||
            datatype == BLPAPI_DATATYPE_CHOICE
        )
end

is_simple_datatype(datatype::BLPDataType) = !is_complex_datatype(datatype)

# an enumeration is also a simple datatype
function is_enumeration_datatype(datatype::BLPDataType) :: Bool
    return datatype == BLPAPI_DATATYPE_ENUMERATION
end

is_choice_datatype(datatype::BLPDataType) = datatype == BLPAPI_DATATYPE_CHOICE

function AbstractSchemaTypeDefinition(handle::Ptr{Cvoid})

    ptr_check(handle, "Failed to create AbstractSchemaTypeDefinition")

    if blpapi_SchemaTypeDefinition_isComplex(handle) != 0

        if blpapi_SchemaTypeDefinition_numElementDefinitions(handle) > 0
            elements = [ SchemaElementDefinition(blpapi_SchemaTypeDefinition_getElementDefinitionAt(handle, i)) for i in 0:(blpapi_SchemaTypeDefinition_numElementDefinitions(handle) - 1) ]
        else
            elements = Vector{SchemaElementDefinition}()
        end

        return ComplexSchemaTypeDefinition(
                BLPName(blpapi_SchemaTypeDefinition_name(handle)),
                unsafe_string(blpapi_SchemaTypeDefinition_description(handle)),
                SchemaStatus(blpapi_SchemaTypeDefinition_status(handle)),
                BLPDataType(blpapi_SchemaTypeDefinition_datatype(handle)),
                elements)

    elseif blpapi_SchemaTypeDefinition_isEnumeration(handle) != 0

        return EnumerationSchemaTypeDefinition(
                BLPName(blpapi_SchemaTypeDefinition_name(handle)),
                unsafe_string(blpapi_SchemaTypeDefinition_description(handle)),
                SchemaStatus(blpapi_SchemaTypeDefinition_status(handle)),
                BLPDataType(blpapi_SchemaTypeDefinition_datatype(handle)),
                BLPConstantList(blpapi_SchemaTypeDefinition_enumeration(handle))
            )

    elseif blpapi_SchemaTypeDefinition_isSimple(handle) != 0
        return SimpleSchemaTypeDefinition(
                BLPName(blpapi_SchemaTypeDefinition_name(handle)),
                unsafe_string(blpapi_SchemaTypeDefinition_description(handle)),
                SchemaStatus(blpapi_SchemaTypeDefinition_status(handle)),
                BLPDataType(blpapi_SchemaTypeDefinition_datatype(handle))
            )
    end

    error("Failed to create AbstractSchemaTypeDefinition: unsupported datatype $(blpapi_SchemaTypeDefinition_datatype(handle)).")
end

function SchemaElementDefinition(handle::Ptr{Cvoid})

    ptr_check(handle, "Failed to create SchemaElementDefinition")

    # alternate_names
    if blpapi_SchemaElementDefinition_numAlternateNames(handle) > 0
        alternate_names = [ BLPName(blpapi_SchemaElementDefinition_getAlternateName(handle, i)) for i in 0:(blpapi_SchemaElementDefinition_numAlternateNames(handle)-1) ]
    else
        alternate_names = Vector{BLPName}()
    end

    return SchemaElementDefinition(
            BLPName(blpapi_SchemaElementDefinition_name(handle)),
            SchemaStatus(blpapi_SchemaElementDefinition_status(handle)),
            AbstractSchemaTypeDefinition(blpapi_SchemaElementDefinition_type(handle)),
            alternate_names,
            UInt64(blpapi_SchemaElementDefinition_minValues(handle)),
            UInt64(blpapi_SchemaElementDefinition_maxValues(handle))
        )
end
