using Pkg
Pkg.activate(".")
Pkg.add([
    "DifferentialEquations",
    "Plots",
    "DataFrames",
    "CSV",
    "JLD2",
    "Literate",
    "IJulia",
    "BenchmarkTools"
])
println("Все пакеты установлены!")
