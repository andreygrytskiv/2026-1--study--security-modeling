# # Функция симуляции потока атак
# Ядро моделирования пуассоновского потока атак.
#
# ## Загрузка пакетов
using Distributions
using Statistics

# ## Функция симуляции
function simulate_attacks(lambda::Float64, T::Float64)
    hourly_counts = rand(Poisson(lambda), floor(Int, T))
    intervals = Float64[]
    total_time = 0.0
    while total_time < T
        tau = rand(Exponential(1/lambda))
        push!(intervals, tau)
        total_time += tau
    end
    if total_time > T
        pop!(intervals)
    end
    attack_times = cumsum(intervals)
    return (hourly_counts = hourly_counts,
            intervals = intervals,
            attack_times = attack_times)
end

function simulate_attacks(p::Dict)
    return simulate_attacks(p[:lambda], p[:T])
end
