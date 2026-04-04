# # Параметрическое исследование экспоненциального роста
#
# ## Активация проекта и загрузка пакетов
using DrWatson
@quickactivate "project"
using DifferentialEquations
using DataFrames
using Plots
using JLD2
using BenchmarkTools

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Определение модели
function exponential_growth!(du, u, p, t)
    a = p.a
    du[1] = a * u[1]
end

# ## Базовые параметры
base_params = Dict(
    :u0 => [1.0],
    :a => 0.3,
    :tspan => (0.0, 10.0),
    :solver => Tsit5(),
    :saveat => 0.1
)

# ## Функция запуска эксперимента
function run_single_experiment(params)
    prob = ODEProblem(exponential_growth!,
        params[:u0], params[:tspan], (a=params[:a],))
    sol = solve(prob, params[:solver]; saveat=params[:saveat])
    return Dict(
        "time_points" => sol.t,
        "population_values" => first.(sol.u),
        "final_population" => last(sol.u)[1],
        "doubling_time" => log(2) / params[:a]
    )
end

# ## Первый запуск
data = run_single_experiment(base_params)
p1 = plot(data["time_points"], data["population_values"],
    label="u(t)", xlabel="Время t", ylabel="Популяция u",
    title="Экспоненциальный рост", lw=2, legend=:topleft)
savefig(plotsdir(script_name, "base_experiment.png"))

# ## Параметрическое сканирование
param_grid = Dict(:a => [0.1, 0.3, 0.5, 0.7, 1.0])
all_params = dict_list(param_grid)
all_results = []
all_dfs = []

for params in all_params
    full_params = merge(base_params, params)
    data = run_single_experiment(full_params)
    push!(all_results, merge(params, Dict(
        :final_population => data["final_population"],
        :doubling_time => data["doubling_time"]
    )))
    push!(all_dfs, DataFrame(
        t = data["time_points"],
        u = data["population_values"],
        a = fill(params[:a], length(data["time_points"]))
    ))
end

# ## Сравнительный график
results_df = DataFrame(all_results)
println("Сводная таблица результатов:")
println(results_df[!, [:a, :final_population, :doubling_time]])

p2 = plot(size=(800, 500), dpi=150)
for (i, params) in enumerate(all_params)
    plot!(p2, all_dfs[i].t, all_dfs[i].u,
        label="a = " * string(params[:a]), lw=2, alpha=0.8)
end
plot!(p2, xlabel="Время, t", ylabel="Популяция, u(t)",
    title="Параметрическое исследование",
    legend=:topleft, grid=true)
savefig(plotsdir(script_name, "parametric_scan.png"))

# ## Сохранение результатов
@save datadir(script_name, "all_results.jld2") base_params results_df
println("Готово!")
