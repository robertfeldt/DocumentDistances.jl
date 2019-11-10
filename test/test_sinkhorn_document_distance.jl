using DocumentDistances: marginals_from_doc

@testset "SinkhornDocumentDistance" begin

@testset "marginals_from_doc" begin

    m1 = marginals_from_doc(["a"], ["a", "b"])
    @test isa(m1, AbstractVector{Float64})
    @test m1[1] == 1.0
    @test m1[2] == 0.0

    m2 = marginals_from_doc(["a", "b"], ["a", "b"])
    @test m2[1] == 0.5
    @test m2[2] == 0.5

    m3 = marginals_from_doc(["c", "b", "b", "c", "c"], ["a", "b", "c"])
    @test m3[1] == 0.0
    @test m3[2] == (2.0/5)
    @test m3[3] == (3.0/5)

    m4 = marginals_from_doc(String[], ["a", "b", "c"])
    @test length(m4) == 3

end # @testset "marginals_from_doc"

end # @testset "SinkhornDocumentDistance"