using DocumentDistances: calc_marginal, frequencies_from_counts
using DocumentDistances: make_vocabulary, update_vocabulary!
using SparseArrays: spzeros

@testset "SinkhornDocumentDistance" begin

@testset "frequencies_from_counts" begin
    fs = frequencies_from_counts(Int[1, 3, 0])
    @test length(fs) == 3
    @test fs[1] == 0.25
    @test fs[2] == 0.75
    @test fs[3] == 0.0
end # @testset "frequencies_from_counts"

@testset "frequencies_from_counts w sparse input" begin
    v = spzeros(3)
    v[1] = 4
    v[2] = 1
    fs = frequencies_from_counts(v)
    @test length(fs) == 3
    @test fs[1] == 0.80
    @test fs[2] == 0.20
    @test fs[3] == 0.00
end # @testset "frequencies_from_counts"

@testset "make_vocabulary and update_vocabulary!" begin
    # @repeat(Vector{String}, Vector{String}) do d1, d2
    for _ in 1:NumRepeatedTests
        d1 = String[randstring(rand(0:5)) for _ in 1:rand(1:20)]
        vocab = make_vocabulary(d1)
        @test length(vocab) == length(unique(d1))
        for w in d1
            @test haskey(vocab, w)
        end
        d2 = String[randstring(rand(0:10)) for _ in 1:rand(1:20)]
        update_vocabulary!(vocab, d2)
        @test length(vocab) == length(unique(vcat(d1, d2)))
        for w in vcat(d1, d2)
            @test haskey(vocab, w)
        end
    end
end # @testset "make_vocabulary and update_vocabulary!"

@testset "calc_marginal" begin
    m1 = calc_marginal(["a"], ["a", "b"])
    @test isa(m1, AbstractVector{Float64})
    @test m1[1] == 1.0
    @test m1[2] == 0.0

    m2 = calc_marginal(["a", "b"], ["a", "b"])
    @test m2[1] == 0.5
    @test m2[2] == 0.5

    m3 = calc_marginal(["c", "b", "b", "c", "c"], ["a", "b", "c"])
    @test m3[1] == 0.0
    @test m3[2] == (2.0/5)
    @test m3[3] == (3.0/5)

    m4 = calc_marginal(String[], ["a", "b", "c"])
    @test length(m4) == 3
end # @testset "calc_marginal"

end # @testset "SinkhornDocumentDistance"