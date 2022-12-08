using Quake
using Documenter

DocMeta.setdocmeta!(Quake, :DocTestSetup, :(using Quake); recursive=true)

makedocs(;
    modules=[Quake],
    authors="Digvijay Patankar <dbpatankar@gmail.com> and contributors",
    repo="https://github.com/dbpatankar/Quake.jl/blob/{commit}{path}#{line}",
    sitename="Quake.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
