module DocumentDistances
using Embeddings
using Distances
using SinkhornDistance

export SinkhornDocumentDistance, evaluate

include("sinkhorn_document_distance.jl")

end  # module