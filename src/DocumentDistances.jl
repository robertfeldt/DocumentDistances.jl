module DocumentDistances
using Distances, JSON, SinkhornDistance

println("Loading the Embeddings package. This takes some time...")
using Embeddings

export SinkhornDocumentDistance, evaluate
export WordDistanceCache, embedding, worddistance

include("word_distance_cache.jl")
include("sinkhorn_document_distance.jl")

end  # module