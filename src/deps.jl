
import Libdl

const libblpapi3 = joinpath(@__DIR__, "..", "deps", "blpapi3_64.dll")

function check_deps()
    global libblpapi3
    if !isfile(libblpapi3)
        error("$libblpapi3 does not exist.")
    end

    if Libdl.dlopen_e(libblpapi3) in (C_NULL, nothing)
        error("$libblpapi3 cannot be opened.")
    end
end
