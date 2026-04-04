# # Параметрическое исследование
# Изучает влияние интенсивности атак на вероятность P(>10).
#
# ## Инициализация
using DrWatson
@quickactivate "project"
using Distributions, Statistics, Plots, StatsPlots, JLD2, Random, CSV, DataFrames
include(srcdir("simulation.jl"))

# ## Параметры
base_params = Dict(
    :T => 24.0,
    :num_hours_for_est => 10000
)
lambda_values = [2.0, 5.0, 8.0, 12.0, 15.0]
Random.seed!(42)
parametric_plots_dir = plotsdir("parameter_sweep")
mkpath(parametric_plots_dir)
summary = Dict{Float64, Dict}()

println("Запуск параметрического исследования...")

# ## Цикл по значениям lambda
for lambda in lambda_values
    params = merge(base_params, Dict(:lambda => lambda))
    filename = datadir("attack_sim", savename(params, "jld2"))
    mkpath(datadir("attack_sim"))

    if isfile(filename)
        println("Загрузка данных для lambda = " * string(lambda))
        @load filename data
    else
        println("Симуляция для lambda = " * string(lambda))
        res = simulate_attacks(lambda, params[:T])
        hourly_sample = rand(Poisson(lambda), params[:num_hours_for_est])
        emp_prob = count(hourly_sample .> 10) / params[:num_hours_for_est]
        theor_prob = 1 - cdf(Poisson(lambda), 10)
        data = Dict(
            :hourly_counts => res.hourly_counts,
            :intervals => res.intervals,
            :attack_times => res.attack_times,
            :emp_prob => emp_prob,
            :theor_prob => theor_prob
        )
        @save filename data params
        println("Сохранено в " * filename)
    end

    hourly_counts = data[:hourly_counts]
    intervals = data[:intervals]
    attack_times = data[:attack_times]

    p1 = histogram(hourly_counts,
        bins = 0:maximum(hourly_counts),
        normalize = :probability,
        label = "Эмпирическая частота",
        xlabel = "Число атак за час",
        ylabel = "Вероятность")
    x_vals = 0:maximum(hourly_counts)
    theor_probs_vals = pdf.(Poisson(lambda), x_vals)
    plot!(p1, x_vals, theor_probs_vals,
        line = :stem, marker = :circle,
        label = "Пуассон", lw=2)
    title!(p1, "Атаки за час (lambda=" * string(lambda) * ")")

    p2 = plot(attack_times, 1:length(attack_times),
        label = "Реализация",
        xlabel = "Время (ч)",
        ylabel = "Накопленное число атак")
    plot!(p2, 0:0.1:params[:T], lambda*(0:0.1:params[:T]),
        label = "Среднее", ls = :dash)
    title!(p2, "Накопленное число атак (lambda=" * string(lambda) * ")")

    p3 = histogram(intervals,
        bins = 30, normalize = :pdf,
        label = "Эмпирическая плотность",
        xlabel = "Интервал (ч)",
        ylabel = "Плотность")
    x_dens = range(0, maximum(intervals), length=100)
    theor_dens = pdf.(Exponential(1/lambda), x_dens)
    plot!(p3, x_dens, theor_dens,
        label = "Экспоненциальная", lw=2)
    title!(p3, "Интервалы (lambda=" * string(lambda) * ")")

    p4 = qqplot(Exponential(1/lambda), intervals,
        qqline = :identity,
        xlabel = "Теоретические квантили",
        ylabel = "Эмпирические квантили",
        title = "QQ-plot (lambda=" * string(lambda) * ")")

    combined = plot(p1, p2, p3, p4, layout = (2,2), size = (1000, 800))
    plot_filename = joinpath(parametric_plots_dir,
        "attack_sim_lambda=" * string(lambda) * ".png")
    savefig(combined, plot_filename)
    println("Графики для lambda=" * string(lambda) * " сохранены")

    summary[lambda] = Dict(
        :emp_prob => data[:emp_prob],
        :theor_prob => data[:theor_prob]
    )
end

# ## Сводные результаты
summary_filename = datadir("parameter_sweep", "summary.jld2")
mkpath(datadir("parameter_sweep"))
@save summary_filename lambda_values summary

lambdas = [l for l in lambda_values]
theor_probs = [summary[l][:theor_prob] for l in lambdas]
emp_probs = [summary[l][:emp_prob] for l in lambdas]

p = plot(lambdas, [theor_probs emp_probs],
    label = ["Теоретическая P(>10)" "Эмпирическая P(>10)"],
    marker = :circle,
    xlabel = "Интенсивность lambda (атак/час)",
    ylabel = "Вероятность P(>10)",
    title = "Зависимость вероятности от интенсивности атак")
savefig(p, plotsdir("parameter_sweep.png"))
println("Общий график сохранён")

df = DataFrame(lambda = lambdas,
    theoretical = theor_probs,
    empirical = emp_probs)
CSV.write(datadir("parameter_sweep", "summary.csv"), df)
println("Таблица сохранена")
