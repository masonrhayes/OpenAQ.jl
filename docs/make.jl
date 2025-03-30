using Documenter
include("../src/OpenAQ.jl")
using .OpenAQ

DocMeta.setdocmeta!(OpenAQ, :DocTestSetup, :(using .OpenAQ); recursive=true)

# Build documentation.
# ====================



makedocs(
    # options
    modules = [OpenAQ],
    doctest = true,
    clean = false,
    sitename = "OpenAQ.jl", 
    remotes = nothing, 
    pages = [
        "Home" => "index.md", 
        "Reference" => "reference.md"
    ]
)