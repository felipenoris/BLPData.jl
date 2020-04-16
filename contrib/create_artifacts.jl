
using Pkg.Artifacts

# This is the path to the Artifacts.toml we will manipulate
artifact_toml = joinpath(@__DIR__, "..", "Artifacts.toml")

# Query the `Artifacts.toml` file for the hash bound to the name "blpapi"
# (returns `nothing` if no such binding exists)
blpapi_hash = artifact_hash("blpapi", artifact_toml)
@assert blpapi_hash == nothing

blpapi_hash = create_artifact() do artifact_dir
    dll_filename = "blpapi3_64.dll"
    local_dll = joinpath(@__DIR__, dll_filename)
    @assert isfile(local_dll) "$local_dll not found"
    cp(local_dll, joinpath(artifact_dir, dll_filename))
end

bind_artifact!(artifact_toml, "blpapi", blpapi_hash)
blpapi_artifact_path = artifact_path(blpapi_hash)
@info("Artifact folder: $blpapi_artifact_path")
tar_sha = archive_artifact(blpapi_hash, joinpath(@__DIR__, "blpapi_cpp_3.12.3.1-windows-x64.tar.gz"))
println("tar SHA: `$tar_sha`")
