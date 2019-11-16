module DocumentDistances
using Distances, JSON, SinkhornDistance, DataDeps, TextAnalysis, SparseArrays

println("Loading the Embeddings package. This takes some time...")
using Embeddings

export SinkhornDocumentDistance, evaluate
export WordDistanceCache, embedding, worddistance, save
export WordMoversDistance
export find_k_nearest_neighbours

abstract type AbstractDocumentDistance <: SemiMetric end

include("word_distance_cache.jl")
include("sinkhorn_document_distance.jl")
include("pdf2text.jl")
#include("textanalysis_interface.jl")
include("word_movers_distance.jl")
include("k_nearest_neighbours.jl")

function __init__()
    register_tika_app_jar_dependency()
end

end  # module