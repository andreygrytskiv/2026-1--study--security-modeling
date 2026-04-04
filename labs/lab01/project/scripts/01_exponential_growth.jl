# # Экспоненциальный рост
# **Цель:** Исследовать решение уравнения du/dt = a*u.
#
# ## Инициализация проекта и загрузка пакетов
using DrWatson
@quickactivate "project"
using DifferentialEquations
using Plots
using DataFrames
using JLD2

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Определение модели
function exponential_growth!(du, u, p, t)
    a = p
    du[1] = a * u[1]
end

# ## Параметры
u0 = [1.0]
a = 0.3
tspan = (0.0, 10.0)

prob = ODEProblem(exponential_growth!, u0, tspan, a)
sol = solve(prob, Tsit5(), saveat=0.1)

# ## Визуализация
plot(sol, label="u(t)", xlabel="Время t", ylabel="Популяция u",
     title="Экспоненциальный рост", lw=2, legend=:topleft)
savefig(plotsdir(script_name, "exponential_growth.png"))

# ## Анализ
df = DataFrame(t=sol.t, u=first.(sol.u))
println("Первые 5 строк результатов:")
println(first(df, 5))
doubling_time = log(2) / a
println("Аналитическое время удвоения: ", round(doubling_time; digits=2))

# ## Сохранение
@save datadir(script_name, "all_results.jld2") df
