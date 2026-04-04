# # Запуск эксперимента с сохранением результатов

using DrWatson
@quickactivate "project"
using Distributions
using Statistics
using JLD2
include(srcdir("simulation.jl"))

params = Dict(
    :lambda => 5.0,
    :T => 24.0,
    :num_hours_for_est => 10000
)

function run_simulation(p)
    lambda = p[:lambda]
    T = p[:T]
    num_hours_for_est = p[:num_hours_for_est]
    res = simulate_attacks(lambda, T)
    hourly_sample = rand(Poisson(lambda), num_hours_for_est)
    emp_prob = count(hourly_sample .> 10) / num_hours_for_est
    theor_prob = 1 - cdf(Poisson(lambda), 10)
    return Dict(
        :hourly_counts => res.hourly_counts,
        :intervals => res.intervals,
        :attack_times => res.attack_times,
        :emp_prob => emp_prob,
        :theor_prob => theor_prob
    )
end

filename = datadir("attack_sim", savename(params, "jld2"))
mkpath(datadir("attack_sim"))

if isfile(filename)
    println("Загрузка существующих данных из " * filename)
    data = load(filename)["data"]
else
    println("Запуск симуляции...")
    data = run_simulation(params)
    println("Сохраняем в файл...")
    @save filename data
    println("Результаты сохранены в " * filename)
end

println("Эмпирическая вероятность P(>10) = " * string(data[:emp_prob]))
println("Теоретическая вероятность = " * string(data[:theor_prob]))
