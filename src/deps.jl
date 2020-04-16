
using Pkg, Pkg.BinaryPlatforms, Pkg.Artifacts, Libdl
import Base: UUID

const libblpapi3 = "blpapi3_64.dll"
libblpapi3_handle = C_NULL # global var to be set at __init__() -> check_deps()

export libblpapi3, check_deps

function check_deps()

    # artifact_dir = abspath(artifact"blpapi") # didn't work
    artifacts_toml = joinpath(@__DIR__, "..", "Artifacts.toml")
    @assert isfile(artifacts_toml) "Couldn't find $artifacts_toml"
    artifact_dict = Pkg.Artifacts.load_artifacts_toml(artifacts_toml)
    artifact_dir = Pkg.Artifacts.do_artifact_str("blpapi", artifact_dict, artifacts_toml, @__MODULE__)

    blpapi_dll_filepath = joinpath(artifact_dir, libblpapi3)
    if !isfile(blpapi_dll_filepath)
        error("Coudln't find DLL artifact at $blpapi_dll_filepath.")
    end

    global libblpapi3_handle = Libdl.dlopen(blpapi_dll_filepath)

    if libblpapi3_handle == C_NULL
        error("$blpapi_dll_filepath cannot be opened.")
    end
end
