
#
# C API
#

"Indicates that the element will be appended to the list on `blpapi_Element_set` functions (`blpapi_defs.h`)."
const BLPAPI_ELEMENT_INDEX_END = 0xffffffff

function blpapi_getVersionInfo(majorVersion::Ref{Cint}, minorVersion::Ref{Cint}, patchVersion::Ref{Cint}, buildVersion::Ref{Cint})
    ccall((:blpapi_getVersionInfo, libblpapi3), Cvoid, (Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}), majorVersion, minorVersion, patchVersion, buildVersion)
end

# const char* blpapi_getLastErrorDescription(int resultCode);
function blpapi_getLastErrorDescription(resultCode::Cint) :: String
    unsafe_string(ccall((:blpapi_getLastErrorDescription, :blpapi3_64), Cstring, (Cint,), resultCode))
end

#
# blpapi_sessionoptions.h
#

#blpapi_SessionOptions_t *blpapi_SessionOptions_create(void);
function blpapi_SessionOptions_create()
    ccall((:blpapi_SessionOptions_create, libblpapi3), Ptr{Cvoid}, ())
end

#void blpapi_SessionOptions_destroy(blpapi_SessionOptions_t *parameters);
function blpapi_SessionOptions_destroy(options_handle::Ptr{Cvoid})
    ccall((:blpapi_SessionOptions_destroy, libblpapi3), Cvoid, (Ptr{Cvoid},), options_handle)
end

#const char *blpapi_SessionOptions_serverHost(
#                                          blpapi_SessionOptions_t *parameters);
function blpapi_SessionOptions_serverHost(opt_handle::Ptr{Cvoid})
    ccall((:blpapi_SessionOptions_serverHost, libblpapi3), Ptr{UInt8}, (Ptr{Cvoid},), opt_handle)
end

#unsigned int blpapi_SessionOptions_serverPort(
#                                          blpapi_SessionOptions_t *parameters);
function blpapi_SessionOptions_serverPort(options_handle::Ptr{Cvoid})
    ccall((:blpapi_SessionOptions_serverPort, libblpapi3), UInt32, (Ptr{Cvoid},), options_handle)
end

#int blpapi_SessionOptions_setServerHost(blpapi_SessionOptions_t *parameters,
#                                        const char              *serverHost);
function blpapi_SessionOptions_setServerHost(options_handle::Ptr{Cvoid}, server_host::AbstractString)
    ccall((:blpapi_SessionOptions_setServerHost, libblpapi3), Cint, (Ptr{Cvoid}, Cstring), options_handle, server_host)
end

#void blpapi_SessionOptions_setClientMode(blpapi_SessionOptions_t *parameters,
#                                         int                      clientMode);
function blpapi_SessionOptions_setClientMode(options_handle::Ptr{Cvoid}, client_mode::Integer)
    ccall((:blpapi_SessionOptions_setClientMode, libblpapi3), Cvoid, (Ptr{Cvoid}, Cint), options_handle, client_mode)
end

#int blpapi_SessionOptions_clientMode(
#                                          blpapi_SessionOptions_t *parameters);
function blpapi_SessionOptions_clientMode(options_handle::Ptr{Cvoid})
    ccall((:blpapi_SessionOptions_clientMode, libblpapi3), Cint, (Ptr{Cvoid},), options_handle)
end

#int blpapi_SessionOptions_setServerPort(blpapi_SessionOptions_t *parameters,
#                                        unsigned short           serverPort);
function blpapi_SessionOptions_setServerPort(options_handle::Ptr{Cvoid}, server_port::UInt16)
    ccall((:blpapi_SessionOptions_setServerPort, libblpapi3), Cint, (Ptr{Cvoid}, UInt16), options_handle, server_port)
end

#int blpapi_SessionOptions_setServiceCheckTimeout(
#                                        blpapi_SessionOptions_t *paramaters,
#                                        int                      timeoutMsecs);
function blpapi_SessionOptions_setServiceCheckTimeout(options_handle::Ptr{Cvoid}, timeout_msecs::Integer)
    ccall((:blpapi_SessionOptions_setServiceCheckTimeout, libblpapi3), Cint, (Ptr{Cvoid}, Cint), options_handle, timeout_msecs)
end

#int blpapi_SessionOptions_setServiceDownloadTimeout(
#                                        blpapi_SessionOptions_t *paramaters,
#                                        int                      timeoutMsecs);
function blpapi_SessionOptions_setServiceDownloadTimeout(options_handle::Ptr{Cvoid}, timeout_msecs::Integer)
    ccall((:blpapi_SessionOptions_setServiceDownloadTimeout, libblpapi3), Cint, (Ptr{Cvoid}, Cint), options_handle, timeout_msecs)
end

#
# blpapi_session.h
#

#blpapi_Session_t* blpapi_Session_create(
#        blpapi_SessionOptions_t *parameters,
#        blpapi_EventHandler_t handler,
#        blpapi_EventDispatcher_t* dispatcher,
#        void *userData);
function blpapi_Session_create(options_handle::Ptr{Cvoid}, event_handler_handle::Ptr{Cvoid}, dispatcher_handler::Ptr{Cvoid}, user_data_handle::Ptr{Cvoid})
    ccall((:blpapi_Session_create, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), options_handle, event_handler_handle, dispatcher_handler, user_data_handle)
end

#void blpapi_Session_destroy(
#        blpapi_Session_t *session);
function blpapi_Session_destroy(session_handle::Ptr{Cvoid})
    ccall((:blpapi_Session_destroy, libblpapi3), Cvoid, (Ptr{Cvoid},), session_handle)
end

#int blpapi_Session_start(
#        blpapi_Session_t *session);
function blpapi_Session_start(session_handle::Ptr{Cvoid})
    ccall((:blpapi_Session_start, libblpapi3), Cint, (Ptr{Cvoid},), session_handle)
end

#int blpapi_Session_stop(
#        blpapi_Session_t* session);
function blpapi_Session_stop(session_handle::Ptr{Cvoid})
    ccall((:blpapi_Session_stop, libblpapi3), Cint, (Ptr{Cvoid},), session_handle)
end

#int blpapi_Session_openService(
#        blpapi_Session_t *session,
#        const char* serviceName);
function blpapi_Session_openService(session_handle::Ptr{Cvoid}, service_name::AbstractString)
    ccall((:blpapi_Session_openService, libblpapi3), Cint, (Ptr{Cvoid}, Cstring), session_handle, service_name)
end

#int blpapi_Session_getService(
#        blpapi_Session_t *session,
#        blpapi_Service_t **service,
#        const char* serviceName);
function blpapi_Session_getService(session_handle::Ptr{Cvoid}, service_handle_ref::Ref{Ptr{Cvoid}}, service_name::AbstractString)
    ccall((:blpapi_Session_getService, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}, Cstring), session_handle, service_handle_ref, service_name)
end

#int blpapi_Session_sendRequest(
#        blpapi_Session_t *session,
#        const blpapi_Request_t *request,
#        blpapi_CorrelationId_t *correlationId,
#        blpapi_Identity_t *identity,
#        blpapi_EventQueue_t *eventQueue,
#        const char *requestLabel,
#        int requestLabelLen);
function blpapi_Session_sendRequest(session_handle::Ptr{Cvoid}, request_handle::Ptr{Cvoid}, correlation_ref::Ref{CorrelationId})
    ccall((:blpapi_Session_sendRequest, libblpapi3), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ref{CorrelationId}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cint), session_handle, request_handle, correlation_ref, C_NULL, C_NULL, C_NULL, 0)
end

#int blpapi_Session_nextEvent(
#        blpapi_Session_t* session,
#        blpapi_Event_t **eventPointer,
#        unsigned int timeoutInMilliseconds);
function blpapi_Session_nextEvent(session_handle::Ptr{Cvoid}, event_handle_ref::Ref{Ptr{Cvoid}}, timeout::Integer)
    ccall((:blpapi_Session_nextEvent, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}, UInt32), session_handle, event_handle_ref, timeout)
end

#
# blpapi_service.h
#

# const char* blpapi_Service_name(blpapi_Service_t *service);
function blpapi_Service_name(service_handle::Ptr{Cvoid})
    ccall((:blpapi_Service_name, libblpapi3), Cstring, (Ptr{Cvoid},), service_handle)
end

# int blpapi_Service_numOperations(blpapi_Service_t *service);
function blpapi_Service_numOperations(service_handle::Ptr{Cvoid})
    ccall((:blpapi_Service_numOperations, libblpapi3), Cint, (Ptr{Cvoid},), service_handle)
end

# int blpapi_Service_getOperationAt(
#        blpapi_Service_t *service,
#        blpapi_Operation_t **operation,
#        size_t index);
function blpapi_Service_getOperationAt(service_handle::Ptr{Cvoid}, operation_handle_ref::Ref{Ptr{Cvoid}}, index::Integer)
    ccall((:blpapi_Service_getOperationAt, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}, Csize_t), service_handle, operation_handle_ref, index)
end

# int blpapi_Service_getOperation(
#        blpapi_Service_t *service,
#        blpapi_Operation_t **operation,
#        const char* nameString,
#        const blpapi_Name_t *name);
function blpapi_Service_getOperation(service_handle::Ptr{Cvoid}, operation_handle_ref::Ref{Ptr{Cvoid}}, name::AbstractString, blpapiname::Ptr{Cvoid})
    ccall((:blpapi_Service_getOperation, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}, Cstring, Ptr{Cvoid}), service_handle, operation_handle_ref, name, blpapiname)
end

#int blpapi_Service_createRequest(
#        blpapi_Service_t* service,
#        blpapi_Request_t** request,
#        const char *operation);
function blpapi_Service_createRequest(service_handle::Ptr{Cvoid}, request_handle_ref::Ref{Ptr{Cvoid}}, operation_name::AbstractString)
    ccall((:blpapi_Service_createRequest, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}, Cstring), service_handle, request_handle_ref, operation_name)
end

# const char* blpapi_Operation_name(blpapi_Operation_t *service);
function blpapi_Operation_name(operation_handle::Ptr{Cvoid})
    ccall((:blpapi_Operation_name, libblpapi3), Cstring, (Ptr{Cvoid},), operation_handle)
end

#int blpapi_Operation_requestDefinition(
#        blpapi_Operation_t *service,
#        blpapi_SchemaElementDefinition_t **requestDefinition);
function blpapi_Operation_requestDefinition(operation_handle::Ptr{Cvoid}, element_definition_handle_ref::Ref{Ptr{Cvoid}})
    ccall((:blpapi_Operation_requestDefinition, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}), operation_handle, element_definition_handle_ref)
end

#int blpapi_Operation_numResponseDefinitions(
#        blpapi_Operation_t *service);
function blpapi_Operation_numResponseDefinitions(operation_handle::Ptr{Cvoid})
    ccall((:blpapi_Operation_numResponseDefinitions, libblpapi3), Cint, (Ptr{Cvoid},), operation_handle)
end

#int blpapi_Operation_responseDefinition(
#        blpapi_Operation_t *service,
#        blpapi_SchemaElementDefinition_t **responseDefinition,
#        size_t index);
function blpapi_Operation_responseDefinition(operation_handle::Ptr{Cvoid}, element_definition_handle_ref::Ref{Ptr{Cvoid}}, index::Integer)
    ccall((:blpapi_Operation_responseDefinition, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}, Csize_t), operation_handle, element_definition_handle_ref, index)
end

#
# blpapi_schema.h
#

#blpapi_Name_t *blpapi_SchemaElementDefinition_name(
#        const blpapi_SchemaElementDefinition_t *field);
function blpapi_SchemaElementDefinition_name(schema_element_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaElementDefinition_name, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), schema_element_handle)
end

#int blpapi_SchemaElementDefinition_status(
#        const blpapi_SchemaElementDefinition_t *field);
function blpapi_SchemaElementDefinition_status(schema_element_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaElementDefinition_status, libblpapi3), Cint, (Ptr{Cvoid},), schema_element_handle)
end

#size_t blpapi_SchemaElementDefinition_numAlternateNames(
#        const blpapi_SchemaElementDefinition_t *field);
function blpapi_SchemaElementDefinition_numAlternateNames(schema_element_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaElementDefinition_numAlternateNames, libblpapi3), Csize_t, (Ptr{Cvoid},), schema_element_handle)
end

#blpapi_Name_t *blpapi_SchemaElementDefinition_getAlternateName(
#        const blpapi_SchemaElementDefinition_t *field,
#        size_t index);
function blpapi_SchemaElementDefinition_getAlternateName(schema_element_handle::Ptr{Cvoid}, index::Integer)
    ccall((:blpapi_SchemaElementDefinition_getAlternateName, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid}, Csize_t), schema_element_handle, index)
end

#size_t blpapi_SchemaElementDefinition_minValues(
#        const blpapi_SchemaElementDefinition_t *field);
function blpapi_SchemaElementDefinition_minValues(schema_element_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaElementDefinition_minValues, libblpapi3), Csize_t, (Ptr{Cvoid},), schema_element_handle)
end

#size_t blpapi_SchemaElementDefinition_maxValues(
#        const blpapi_SchemaElementDefinition_t *field);
function blpapi_SchemaElementDefinition_maxValues(schema_element_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaElementDefinition_maxValues, libblpapi3), Csize_t, (Ptr{Cvoid},), schema_element_handle)
end

#blpapi_SchemaTypeDefinition_t *blpapi_SchemaElementDefinition_type(
#        const blpapi_SchemaElementDefinition_t *field);
function blpapi_SchemaElementDefinition_type(schema_element_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaElementDefinition_type, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), schema_element_handle)
end

#blpapi_Name_t *blpapi_SchemaTypeDefinition_name(
#        const blpapi_SchemaTypeDefinition_t *type);
function blpapi_SchemaTypeDefinition_name(schema_type_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaTypeDefinition_name, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), schema_type_handle)
end

#const char *blpapi_SchemaTypeDefinition_description(
#        const blpapi_SchemaTypeDefinition_t *type);
function blpapi_SchemaTypeDefinition_description(schema_type_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaTypeDefinition_description, libblpapi3), Cstring, (Ptr{Cvoid},), schema_type_handle)
end

#int blpapi_SchemaTypeDefinition_status(
#        const blpapi_SchemaTypeDefinition_t *type);
function blpapi_SchemaTypeDefinition_status(schema_type_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaTypeDefinition_status, libblpapi3), Cint, (Ptr{Cvoid},), schema_type_handle)
end

#int blpapi_SchemaTypeDefinition_datatype(
#        const blpapi_SchemaTypeDefinition_t *type);
function blpapi_SchemaTypeDefinition_datatype(schema_type_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaTypeDefinition_datatype, libblpapi3), Cint, (Ptr{Cvoid},), schema_type_handle)
end

#int blpapi_SchemaTypeDefinition_isComplex(
#        const blpapi_SchemaTypeDefinition_t *type);
function blpapi_SchemaTypeDefinition_isComplex(schema_type_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaTypeDefinition_isComplex, libblpapi3), Cint, (Ptr{Cvoid},), schema_type_handle)
end

#int blpapi_SchemaTypeDefinition_isSimple(
#        const blpapi_SchemaTypeDefinition_t *type);
function blpapi_SchemaTypeDefinition_isSimple(schema_type_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaTypeDefinition_isSimple, libblpapi3), Cint, (Ptr{Cvoid},), schema_type_handle)
end

#int blpapi_SchemaTypeDefinition_isEnumeration(
#        const blpapi_SchemaTypeDefinition_t *type);
function blpapi_SchemaTypeDefinition_isEnumeration(schema_type_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaTypeDefinition_isEnumeration, libblpapi3), Cint, (Ptr{Cvoid},), schema_type_handle)
end

#size_t blpapi_SchemaTypeDefinition_numElementDefinitions(
#        const blpapi_SchemaTypeDefinition_t *type);
function blpapi_SchemaTypeDefinition_numElementDefinitions(schema_type_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaTypeDefinition_numElementDefinitions, libblpapi3), Csize_t, (Ptr{Cvoid},), schema_type_handle)
end

#blpapi_SchemaElementDefinition_t*
#blpapi_SchemaTypeDefinition_getElementDefinitionAt(
#        const blpapi_SchemaTypeDefinition_t *type,
#        size_t index);
function blpapi_SchemaTypeDefinition_getElementDefinitionAt(schema_type_handle::Ptr{Cvoid}, index::Integer)
    ccall((:blpapi_SchemaTypeDefinition_getElementDefinitionAt, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid}, Csize_t), schema_type_handle, index)
end

#blpapi_ConstantList_t*
#blpapi_SchemaTypeDefinition_enumeration(
#        const blpapi_SchemaTypeDefinition_t *element);
function blpapi_SchemaTypeDefinition_enumeration(schema_type_handle::Ptr{Cvoid})
    ccall((:blpapi_SchemaTypeDefinition_enumeration, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), schema_type_handle)
end

#
# blpapi_name.h
#

#void blpapi_Name_destroy(
#        blpapi_Name_t *name);
function blpapi_Name_destroy(name_handle::Ptr{Cvoid})
    ccall((:blpapi_Name_destroy, libblpapi3), Cvoid, (Ptr{Cvoid},), name_handle)
end

#const char* blpapi_Name_string(
#        const blpapi_Name_t *name);
function blpapi_Name_string(name_handle::Ptr{Cvoid})
    ccall((:blpapi_Name_string, libblpapi3), Cstring, (Ptr{Cvoid},), name_handle)
end

#blpapi_Name_t* blpapi_Name_findName(
#        const char* nameString);
function blpapi_Name_findName(name::AbstractString)
    ccall((:blpapi_Name_findName, libblpapi3), Ptr{Cvoid}, (Cstring,), name)
end

#blpapi_Name_t* blpapi_Name_create(
#        const char* nameString);
function blpapi_Name_create(name::AbstractString)
    ccall((:blpapi_Name_create, libblpapi3), Ptr{Cvoid}, (Cstring,), name)
end

#
# blpapi_constant.h
#

#blpapi_Name_t* blpapi_Constant_name(
#        const blpapi_Constant_t *constant);
function blpapi_Constant_name(const_handle::Ptr{Cvoid})
    ccall((:blpapi_Constant_name, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), const_handle)
end

#const char* blpapi_Constant_description(
#        const blpapi_Constant_t *constant);
function blpapi_Constant_description(const_handle::Ptr{Cvoid})
    ccall((:blpapi_Constant_description, libblpapi3), Cstring, (Ptr{Cvoid},), const_handle)
end

#int blpapi_Constant_status(
#        const blpapi_Constant_t *constant);
function blpapi_Constant_status(const_handle::Ptr{Cvoid})
    ccall((:blpapi_Constant_status, libblpapi3), Cint, (Ptr{Cvoid},), const_handle)
end

#int blpapi_Constant_datatype(
#        const blpapi_Constant_t *constant);
function blpapi_Constant_datatype(const_handle::Ptr{Cvoid})
    ccall((:blpapi_Constant_datatype, libblpapi3), Cint, (Ptr{Cvoid},), const_handle)
end

#int blpapi_Constant_getValueAsChar(
#    const blpapi_Constant_t *constant,
#    blpapi_Char_t *buffer);
function blpapi_Constant_getValueAsChar(const_handle::Ptr{Cvoid}, buffer::Ref{Cchar})
    ccall((:blpapi_Constant_getValueAsChar, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Cchar}), const_handle, buffer)
end

#int blpapi_Constant_getValueAsInt32(
#    const blpapi_Constant_t *constant,
#    blpapi_Int32_t *buffer);
function blpapi_Constant_getValueAsInt32(const_handle::Ptr{Cvoid}, buffer::Ref{Cint})
    ccall((:blpapi_Constant_getValueAsInt32, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Cint}), const_handle, buffer)
end

#int blpapi_Constant_getValueAsInt64(
#    const blpapi_Constant_t *constant,
#    blpapi_Int64_t *buffer);
function blpapi_Constant_getValueAsInt64(const_handle::Ptr{Cvoid}, buffer::Ref{Int64})
    ccall((:blpapi_Constant_getValueAsInt64, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Int64}), const_handle, buffer)
end

#int blpapi_Constant_getValueAsFloat32(
#    const blpapi_Constant_t *constant,
#    blpapi_Float32_t *buffer);
function blpapi_Constant_getValueAsFloat32(const_handle::Ptr{Cvoid}, buffer::Ref{Float32})
    ccall((:blpapi_Constant_getValueAsFloat32, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Float32}), const_handle, buffer)
end

#int blpapi_Constant_getValueAsFloat64(
#    const blpapi_Constant_t *constant,
#    blpapi_Float64_t *buffer);
function blpapi_Constant_getValueAsFloat64(const_handle::Ptr{Cvoid}, buffer::Ref{Float64})
    ccall((:blpapi_Constant_getValueAsFloat64, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Float64}), const_handle, buffer)
end

#int blpapi_Constant_getValueAsDatetime(
#    const blpapi_Constant_t *constant,
#    blpapi_Datetime_t *buffer);
function blpapi_Constant_getValueAsDatetime(const_handle::Ptr{Cvoid}, buffer::Ref{BLPDateTime})
    ccall((:blpapi_Constant_getValueAsDatetime, libblpapi3), Cint, (Ptr{Cvoid}, Ref{BLPDateTime}), const_handle, buffer)
end

#int blpapi_Constant_getValueAsString(
#    const blpapi_Constant_t *constant,
#    const char **buffer);
function blpapi_Constant_getValueAsString(const_handle::Ptr{Cvoid}, buffer::Ref{Cstring})
    ccall((:blpapi_Constant_getValueAsString, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Cstring}), const_handle, buffer)
end

#blpapi_Name_t* blpapi_ConstantList_name(
#        const blpapi_ConstantList_t *list);
function blpapi_ConstantList_name(list_handle::Ptr{Cvoid})
    ccall((:blpapi_ConstantList_name, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), list_handle)
end

#const char* blpapi_ConstantList_description(
#        const blpapi_ConstantList_t *list);
function blpapi_ConstantList_description(list_handle::Ptr{Cvoid})
    ccall((:blpapi_ConstantList_description, libblpapi3), Cstring, (Ptr{Cvoid},), list_handle)
end

#int blpapi_ConstantList_numConstants(
#        const blpapi_ConstantList_t *list);
function blpapi_ConstantList_numConstants(list_handle::Ptr{Cvoid})
    ccall((:blpapi_ConstantList_numConstants, libblpapi3), Cint, (Ptr{Cvoid},), list_handle)
end

#int blpapi_ConstantList_datatype(
#        const blpapi_ConstantList_t *constant);
function blpapi_ConstantList_datatype(list_handle::Ptr{Cvoid})
    ccall((:blpapi_ConstantList_datatype, libblpapi3), Cint, (Ptr{Cvoid},), list_handle)
end

#int blpapi_ConstantList_status(
#        const blpapi_ConstantList_t *list);
function blpapi_ConstantList_status(list_handle::Ptr{Cvoid})
    ccall((:blpapi_ConstantList_status, libblpapi3), Cint, (Ptr{Cvoid},), list_handle)
end

#blpapi_Constant_t* blpapi_ConstantList_getConstantAt(
#        const blpapi_ConstantList_t *constant,
#        size_t index);
function blpapi_ConstantList_getConstantAt(list_handle::Ptr{Cvoid}, index::Integer)
    ccall((:blpapi_ConstantList_getConstantAt, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid}, Csize_t), list_handle, index)
end

#
# blpapi_request.h
#

#void blpapi_Request_destroy(
#        blpapi_Request_t *request);
function blpapi_Request_destroy(request_handle::Ptr{Cvoid})
    ccall((:blpapi_Request_destroy, libblpapi3), Cvoid, (Ptr{Cvoid},), request_handle)
end

#blpapi_Element_t* blpapi_Request_elements(
#        blpapi_Request_t *request);
function blpapi_Request_elements(request_handle::Ptr{Cvoid})
    ccall((:blpapi_Request_elements, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), request_handle)
end

#
# blpapi_element.h
#

#BLPAPI_EXPORT blpapi_Name_t*
#blpapi_Element_name(const blpapi_Element_t *element);
function blpapi_Element_name(element_handle::Ptr{Cvoid})
    ccall((:blpapi_Element_name, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), element_handle)
end

#BLPAPI_EXPORT blpapi_SchemaElementDefinition_t*
#blpapi_Element_definition(const blpapi_Element_t* element);
function blpapi_Element_definition(element_handle::Ptr{Cvoid})
    ccall((:blpapi_Element_definition, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), element_handle)
end

#BLPAPI_EXPORT int blpapi_Element_datatype (
#        const blpapi_Element_t* element);
function blpapi_Element_datatype(element_handle::Ptr{Cvoid})
    ccall((:blpapi_Element_datatype, libblpapi3), Cint, (Ptr{Cvoid},), element_handle)
end

#int blpapi_Element_getElement(
#        const blpapi_Element_t *element,
#        blpapi_Element_t **result,
#        const char* nameString,
#        const blpapi_Name_t *name);
function blpapi_Element_getElement(element_handle::Ptr{Cvoid}, result_element_handle_ref::Ref{Ptr{Cvoid}}, element_name_string::Ptr{UInt8}, element_blp_name::Ptr{Cvoid})
    ccall((:blpapi_Element_getElement, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}, Ptr{UInt8}, Ptr{Cvoid}), element_handle, result_element_handle_ref, element_name_string, element_blp_name)
end

#int blpapi_Element_getElementAt(
#        const blpapi_Element_t* element,
#        blpapi_Element_t **result,
#        size_t position);
function blpapi_Element_getElementAt(element_handle::Ptr{Cvoid}, result_element_handle_ref::Ref{Ptr{Cvoid}}, index::Csize_t)
    ccall((:blpapi_Element_getElementAt, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}, Csize_t), element_handle, result_element_handle_ref, index)
end

#int blpapi_Element_getChoice(
#        const blpapi_Element_t *element,
#        blpapi_Element_t **result);
function blpapi_Element_getChoice(element_handle::Ptr{Cvoid}, result_element_handle_ref::Ref{Ptr{Cvoid}})
    ccall((:blpapi_Element_getChoice, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}), element_handle, result_element_handle_ref)
end

#int blpapi_Element_hasElement(
#        const blpapi_Element_t *element,
#        const char* nameString,
#        const blpapi_Name_t *name);
function blpapi_Element_hasElement(element_handle::Ptr{Cvoid}, element_name_string::Ptr{UInt8}, element_blp_name::Ptr{Cvoid})
    ccall((:blpapi_Element_hasElement, libblpapi3), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cvoid}), element_handle, element_name_string, element_blp_name)
end

#BLPAPI_EXPORT int blpapi_Element_isArray(
#        const blpapi_Element_t* element);
function blpapi_Element_isArray(element_handle::Ptr{Cvoid})
    ccall((:blpapi_Element_isArray, libblpapi3), Cint, (Ptr{Cvoid},), element_handle)
end

#int blpapi_Element_setValueString(
#        blpapi_Element_t *element,
#        const char *value,
#        size_t index);
function blpapi_Element_setValueString(element_handle::Ptr{Cvoid}, value::AbstractString, index::Integer)
    ccall((:blpapi_Element_setValueString, libblpapi3), Cint, (Ptr{Cvoid}, Cstring, Csize_t), element_handle, value, index)
end

#int blpapi_Element_setValueBool(
#        blpapi_Element_t *element,
#        blpapi_Bool_t value,
#        size_t index);
function blpapi_Element_setValueBool(element_handle::Ptr{Cvoid}, value::Bool, index::Integer)
    ccall((:blpapi_Element_setValueBool, libblpapi3), Cint, (Ptr{Cvoid}, Cint, Csize_t), element_handle, value, index)
end

#BLPAPI_EXPORT size_t blpapi_Element_numElements(
#        const blpapi_Element_t* element);
function blpapi_Element_numElements(element_handle::Ptr{Cvoid})
    ccall((:blpapi_Element_numElements, libblpapi3), Csize_t, (Ptr{Cvoid},), element_handle)
end

#BLPAPI_EXPORT size_t blpapi_Element_numValues(
#        const blpapi_Element_t* element);
function blpapi_Element_numValues(element_handle::Ptr{Cvoid})
    ccall((:blpapi_Element_numValues, libblpapi3), Csize_t, (Ptr{Cvoid},), element_handle)
end

#int blpapi_Element_isNullValue(
#        const blpapi_Element_t* element,
#        size_t position);
function blpapi_Element_isNullValue(element_handle::Ptr{Cvoid}, index::Integer)
    ccall((:blpapi_Element_isNullValue, libblpapi3), Cint, (Ptr{Cvoid}, Csize_t), element_handle, index)
end

#BLPAPI_EXPORT int blpapi_Element_isNull(
#        const blpapi_Element_t* element);
function blpapi_Element_isNull(element_handle::Ptr{Cvoid})
    ccall((:blpapi_Element_isNull, libblpapi3), Cint, (Ptr{Cvoid},), element_handle)
end

#int blpapi_Element_getValueAsBool(
#        const blpapi_Element_t *element,
#        blpapi_Bool_t *buffer,
#        size_t index);
function blpapi_Element_getValueAsBool(element_handle::Ptr{Cvoid}, buffer_ref::Ref{Cint}, index::Integer)
    ccall((:blpapi_Element_getValueAsBool, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Cint}, Csize_t), element_handle, buffer_ref, index)
end

#int blpapi_Element_getValueAsChar(
#        const blpapi_Element_t *element,
#        blpapi_Char_t *buffer,
#        size_t index);
function blpapi_Element_getValueAsChar(element_handle::Ptr{Cvoid}, buffer_ref::Ref{Cchar}, index::Integer)
    ccall((:blpapi_Element_getValueAsChar, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Cchar}, Csize_t), element_handle, buffer_ref, index)
end

#int blpapi_Element_getValueAsInt32(
#        const blpapi_Element_t *element,
#        blpapi_Int32_t *buffer,
#        size_t index);
function blpapi_Element_getValueAsInt32(element_handle::Ptr{Cvoid}, buffer_ref::Ref{Int32}, index::Integer)
    ccall((:blpapi_Element_getValueAsInt32, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Int32}, Csize_t), element_handle, buffer_ref, index)
end

#int blpapi_Element_getValueAsInt64(
#        const blpapi_Element_t *element,
#        blpapi_Int64_t *buffer,
#        size_t index);
function blpapi_Element_getValueAsInt64(element_handle::Ptr{Cvoid}, buffer_ref::Ref{Int64}, index::Integer)
    ccall((:blpapi_Element_getValueAsInt64, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Int64}, Csize_t), element_handle, buffer_ref, index)
end

#int blpapi_Element_getValueAsFloat32(
#        const blpapi_Element_t *element,
#        blpapi_Float32_t *buffer,
#        size_t index);
function blpapi_Element_getValueAsFloat32(element_handle::Ptr{Cvoid}, buffer_ref::Ref{Float32}, index::Integer)
    ccall((:blpapi_Element_getValueAsFloat32, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Float32}, Csize_t), element_handle, buffer_ref, index)
end

#int blpapi_Element_getValueAsFloat64(
#        const blpapi_Element_t *element,
#        blpapi_Float64_t *buffer,
#        size_t index);
function blpapi_Element_getValueAsFloat64(element_handle::Ptr{Cvoid}, buffer_ref::Ref{Float64}, index::Integer)
    ccall((:blpapi_Element_getValueAsFloat64, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Float64}, Csize_t), element_handle, buffer_ref, index)
end

#int blpapi_Element_getValueAsString(
#        const blpapi_Element_t *element,
#        const char **buffer,
#        size_t index);
function blpapi_Element_getValueAsString(element_handle::Ptr{Cvoid}, buffer_ref::Ref{Cstring}, index::Integer)
    ccall((:blpapi_Element_getValueAsString, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Cstring}, Csize_t), element_handle, buffer_ref, index)
end

#int blpapi_Element_getValueAsDatetime(
#        const blpapi_Element_t *element,
#        blpapi_Datetime_t *buffer,
#        size_t index);
function blpapi_Element_getValueAsDatetime(element_handle::Ptr{Cvoid}, buffer_ref::Ref{BLPDateTime}, index::Integer)
    ccall((:blpapi_Element_getValueAsDatetime, libblpapi3), Cint, (Ptr{Cvoid}, Ref{BLPDateTime}, Csize_t), element_handle, buffer_ref, index)
end

#int blpapi_Element_getValueAsHighPrecisionDatetime(
#        const blpapi_Element_t *element,
#        blpapi_HighPrecisionDatetime_t *buffer,
#        size_t index);

#int blpapi_Element_getValueAsElement(
#        const blpapi_Element_t *element,
#        blpapi_Element_t **buffer,
#        size_t index);
function blpapi_Element_getValueAsElement(element_handle::Ptr{Cvoid}, buffer_ref::Ref{Ptr{Cvoid}}, index::Integer)
    ccall((:blpapi_Element_getValueAsElement, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}, Csize_t), element_handle, buffer_ref, index)
end

#int blpapi_Element_getValueAsName(
#        const blpapi_Element_t *element,
#        blpapi_Name_t **buffer,
#        size_t index);

#
# blpapi_event.h
#

#int blpapi_Event_eventType(
#        const blpapi_Event_t *event);
function blpapi_Event_eventType(event_handle::Ptr{Cvoid})
    ccall((:blpapi_Event_eventType, libblpapi3), Cint, (Ptr{Cvoid},), event_handle)
end

#int blpapi_Event_release(
#        const blpapi_Event_t *event);
function blpapi_Event_release(event_handle::Ptr{Cvoid})
    ccall((:blpapi_Event_release, libblpapi3), Cint, (Ptr{Cvoid},), event_handle)
end

#void blpapi_MessageIterator_destroy(
#        blpapi_MessageIterator_t* iterator);
function blpapi_MessageIterator_destroy(msg_iterator_handle::Ptr{Cvoid})
    ccall((:blpapi_MessageIterator_destroy, libblpapi3), Cvoid, (Ptr{Cvoid},), msg_iterator_handle)
end

#blpapi_MessageIterator_t* blpapi_MessageIterator_create(
#        const blpapi_Event_t *event);
function blpapi_MessageIterator_create(event_handle::Ptr{Cvoid})
    ccall((:blpapi_MessageIterator_create, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), event_handle)
end

#int blpapi_MessageIterator_next(
#        blpapi_MessageIterator_t* iterator,
#        blpapi_Message_t** result);
function blpapi_MessageIterator_next(msg_iter_handle::Ptr{Cvoid}, result_msg_handle_ref::Ref{Ptr{Cvoid}})
    ccall((:blpapi_MessageIterator_next, libblpapi3), Cint, (Ptr{Cvoid}, Ref{Ptr{Cvoid}}), msg_iter_handle, result_msg_handle_ref)
end

#
# blpapi_message.h
#

#blpapi_Element_t* blpapi_Message_elements(
#        const blpapi_Message_t *message);
function blpapi_Message_elements(message_handle::Ptr{Cvoid})
    ccall((:blpapi_Message_elements, libblpapi3), Ptr{Cvoid}, (Ptr{Cvoid},), message_handle)
end

#int blpapi_Message_numCorrelationIds(
#        const blpapi_Message_t *message);
function blpapi_Message_numCorrelationIds(message_handle::Ptr{Cvoid})
    ccall((:blpapi_Message_numCorrelationIds, libblpapi3), Cint, (Ptr{Cvoid},), message_handle)
end

#blpapi_CorrelationId_t blpapi_Message_correlationId(
#        const blpapi_Message_t *message,
#        size_t index);
function blpapi_Message_correlationId(message_handle::Ptr{Cvoid}, index::Integer)
    ccall((:blpapi_Message_correlationId, libblpapi3), CorrelationId, (Ptr{Cvoid}, Csize_t), message_handle, index)
end
