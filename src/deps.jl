
using Pkg, Libdl

function shared_lib_filename()
    if Sys.iswindows()
        return "blpapi3_64.dll"

    elseif Sys.islinux() || Sys.isapple()
        return "libblpapi3_64.so"
    end

    error("Unsupported system.")
end

libblpapi3_path = "" # global var with path to the shared library
libblpapi3_handle = C_NULL # global var to be set at __init__() -> check_deps()
const libblpapi3 = shared_lib_filename()

function get_artifact_dir()
    #artifact_dir = abspath(artifact"blpapi") # didn't work
    artifacts_toml = joinpath(@__DIR__, "..", "Artifacts.toml")
    @assert isfile(artifacts_toml) "Couldn't find $artifacts_toml"
    artifact_dict = Pkg.Artifacts.load_artifacts_toml(artifacts_toml)
    artifact_dir = Pkg.Artifacts.@artifact_str("blpapi")
end

get_libblpapi_artifact_filepath() = joinpath(get_artifact_dir(), libblpapi3)

# called by __init__()
function check_deps()

    global libblpapi3_path
    global libblpapi3_handle

    if Sys.islinux()
        try
            libblpapi3_handle = dlopen(libblpapi3)
        catch err
            if isa(err, ErrorException) && endswith(err.msg, "$libblpapi3: cannot open shared object file: No such file or directory")
                @warn("### WARNING ### \nCouldn't find $libblpapi3 shared lib.\nCopy the file $(get_libblpapi_artifact_filepath()) to your `LD_LIBRARY_PATH` and restart Julia.")
                return
            else
                rethrow(err)
            end
        end

        if libblpapi3_handle == C_NULL
            error("$libblpapi3 cannot be opened.")
        end
    else
        libblpapi3_path = get_libblpapi_artifact_filepath()
        if !isfile(libblpapi3_path)
            error("Couldn't find shared library artifact at $libblpapi3_path.")
        end

        libblpapi3_handle = dlopen(libblpapi3_path)
        if libblpapi3_handle == C_NULL
            error("$libblpapi3_path cannot be opened.")
        end
    end
end
