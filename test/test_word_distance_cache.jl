using DocumentDistances: embeddingname2embedding
using Embeddings, JSON

@testset "WordDistanceCache" begin

@testset "embeddingname2embedding" begin

    @test embeddingname2embedding(:word2vec) == (Embeddings.Word2Vec, 1)
    @test embeddingname2embedding(:Word2Vec) == (Embeddings.Word2Vec, 1)
    @test embeddingname2embedding("Word2Vec") == (Embeddings.Word2Vec, 1)

    @test embeddingname2embedding("GloVe") == (Embeddings.GloVe{:en}, 4)
    @test embeddingname2embedding(:GloVe42b300d) == (Embeddings.GloVe{:en}, 5)

end # @testset "embeddingname2embedding"

@testset "basic use" begin

    wdc = WordDistanceCache(".", :Word2Vec)

    e1 = embedding(wdc, "President")
    @test typeof(e1) <: AbstractVector

    e2 = embedding(wdc, "Obama")
    @test length(e1) == length(e2)

    # Obama has been president but not plumber so distance to latter should be higher.
    d12 = worddistance(wdc, "Obama", "president")
    d13 = worddistance(wdc, "Obama", "plumber")
    @test d12 < d13

end # @testset "basic use"

@testset "json and distances_as_array_for_json" begin

    wdc = WordDistanceCache(".", :Word2Vec)
    dist = worddistance(wdc, "speak", "talk")
    ary = DocumentDistances.distances_as_array_for_json(wdc)

    @test length(ary) == 1
    @test ary[1][1] == "speak"
    @test ary[1][2] == "talk"
    @test isa(ary[1][3], Float64)
    @test ary[1][3] == dist

    worddistance(wdc, "press", "media")
    worddistance(wdc, "press", "speak")
    worddistance(wdc, "press", "media") # This should not add a new entry since already cached...
    ary = DocumentDistances.distances_as_array_for_json(wdc)
    @test length(ary) == 3

    js = DocumentDistances.json(wdc)
    @test isa(js, AbstractString)
    pd = JSON.parse(js)
    @test isa(pd, Dict)
    @test haskey(pd, "meta")
    @test haskey(pd, "distances")
    @test length(pd["distances"]) == length(ary)

end # @testset "json and distances_as_array_for_json"

@testset "save and load_word_distance_cache" begin

    wdc = WordDistanceCache(".", :Word2Vec)
    dist = worddistance(wdc, "robert", "programmer")

    defaultcachefile = joinpath(".", DocumentDistances.DefaultWordCacheFilename)
    isfile(defaultcachefile) && rm(defaultcachefile) # Ensure not already there

    DocumentDistances.save(wdc)
    @test isfile(defaultcachefile)

    wdc2 = DocumentDistances.load_word_distance_cache(defaultcachefile)
    @test length(wdc2.worddistances) == length(wdc.worddistances)

    rm(defaultcachefile) # clean up again after us...

end # @testset "save and load_word_distance_cache"

end # @testset "WordDistanceCache"