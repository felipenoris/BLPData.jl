
using Documenter, BLPData

makedocs(
    sitename = "BLPData.jl",
    modules = [ BLPData ],
    pages = [ "Home" => "index.md",
              "Tutorial" => "tutorial.md",
              "API Reference" => "api.md" ]
)

deploydocs(
    repo = "github.com/felipenoris/BLPData.jl.git",
    target = "build",
)
