using DrWatson
@quickactivate "project"
println("Проект активирован: ", projectdir())
for pkg in ["DrWatson","DifferentialEquations","Plots",
            "DataFrames","JLD2","Literate","IJulia","BenchmarkTools"]
    try
        eval(Meta.parse("using " * pkg))
        println(" + ", pkg)
    catch
        println(" - ", pkg, " -- ошибка")
    end
end
println("Корень: ", projectdir())
println("Данные: ", datadir())
println("Графики: ", plotsdir())
