using Pkg
Pkg.add("DrWatson")
using DrWatson
initialize_project("project"; authors="Andrew Grytskiv", git=false)
println("Проект создан")
