
using Documenter, BLPData

makedocs(
    sitename = "BLPData.jl",
    modules = [ BLPData ],
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
    ],
    checkdocs=:none,
)

deploydocs(
    repo = "github.com/felipenoris/BLPData.jl.git",
    target = "build",
)
