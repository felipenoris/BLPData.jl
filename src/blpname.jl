
BLPName(name::Symbol) = BLPName(blpapi_Name_create(String(name)))
has_name(blp_name::BLPName, name::Symbol) = blp_name.symbol == name
has_name(blp_name::BLPName, name::AbstractString) = has_name(blp_name, Symbol(name))
