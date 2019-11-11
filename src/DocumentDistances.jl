module DocumentDistances
using Distances, JSON, SinkhornDistance, DataDeps

println("Loading the Embeddings package. This takes some time...")
using Embeddings

export SinkhornDocumentDistance, evaluate
export WordDistanceCache, embedding, worddistance, save

include("word_distance_cache.jl")
include("sinkhorn_document_distance.jl")
include("pdf2text.jl")

function __init__()
    register_tika_app_jar_dependency()
end

end  # module