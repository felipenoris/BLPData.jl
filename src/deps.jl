
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
const libblpapi3 = shared_lib_filename()
libblpapi3_handle = C_NULL # global var to be set at __init__() -> check_deps()

# called by __init__()
function check_deps()

    #artifact_dir = abspath(artifact"blpapi") # didn't work
    artifacts_toml = joinpath(@__DIR__, "..", "Artifacts.toml")
    @assert isfile(artifacts_toml) "Couldn't find $artifacts_toml"
    artifact_dict = Pkg.Artifacts.load_artifacts_toml(artifacts_toml)
    artifact_dir = Pkg.Artifacts.do_artifact_str("blpapi", artifact_dict, artifacts_toml, @__MODULE__)

    global libblpapi3_path = joinpath(artifact_dir, libblpapi3)
    if !isfile(libblpapi3_path)
        error("Couldn't find shared library artifact at $libblpapi3_path.")
    end

    global libblpapi3_handle = dlopen(libblpapi3_path)
    if libblpapi3_handle == C_NULL
        error("$libblpapi3_path cannot be opened.")
    end
end
