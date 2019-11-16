using DocumentDistances, Test

using Random
const NumRepeatedTests = 100

@testset "DocumentDistances test suite" begin

include("test_word_distance_cache.jl")
include("test_sinkhorn_document_distance.jl")
include("test_readme_examples.jl")
include("test_pdf2text.jl")

end