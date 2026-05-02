# # Визуализация и анализ графа атак

using DrWatson
@quickactivate "project"
using Graphs, JLD2, Plots, GraphRecipes
include(srcdir("attack_graph.jl"))

params = Dict(:n => 20, :edge_prob => 0.2, :source => 1, :target => 20)
filename = datadir("attack_graph", savename(params, "jld2"))
@load filename data

g = data[:graph]
metrics = data[:metrics]
pagerank = metrics[:pagerank]

norm_rank = (pagerank .- minimum(pagerank)) ./ (maximum(pagerank) - minimum(pagerank))
colors = [cgrad(:RdYlGn, rev = true)[norm_rank[i]] for i = 1:nv(g)]

graphplot(
    g,
    nodeshape = :circle,
    curves = false,
    linecolor = :black,
    nodecolor = colors,
    nodelabel = 1:nv(g),
    title = "Граф атак (цвет = PageRank)",
    size = (800, 600),
)
savefig(plotsdir("attack_graph.png"))
println("График сохранён в " * plotsdir("attack_graph.png"))

println("=== Анализ графа атак ===")
println("Количество узлов: " * string(nv(g)))
println("Количество рёбер: " * string(ne(g)))
println("Количество путей: " * string(length(data[:paths])))

if !isempty(data[:paths])
    println("Длины путей: " * string([length(p) for p in data[:paths]]))
    println("Наиболее вероятный путь: " * string(data[:likely_path]))
end

println("\nТоп-5 узлов по in-degree:")
top_indeg = sortperm(metrics[:in_degree], rev = true)[1:5]
for i in top_indeg
    println(" Узел " * string(i) * ": in-degree = " * string(metrics[:in_degree][i]))
end

println("\nТоп-5 узлов по PageRank:")
top_pr = sortperm(metrics[:pagerank], rev = true)[1:5]
for i in top_pr
    println(" Узел " * string(i) * ": PageRank = " * string(round(metrics[:pagerank][i], digits=4)))
end
