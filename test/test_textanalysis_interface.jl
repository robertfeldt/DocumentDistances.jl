using DocumentDistances: findclosetoken, filtertokens
using DocumentDistances: FilteredNGramDocument, ngrams
using TextAnalysis

@testset "TextAnalysis interface" begin

@testset "findclosetoken" begin
    @test findclosetoken("president") == "president"
    @test findclosetoken("president.") == "president"
    @test findclosetoken("president-") == "president"
    @test findclosetoken("president,") == "president"

    @test findclosetoken("President") == "president"
    @test findclosetoken("President.") == "president"
    @test findclosetoken("President-") == "president"
    @test findclosetoken("President,") == "president"

    @test findclosetoken("ewirjp2or,") === nothing
end # @testset "findclosetoken"

@testset "filtertokens" begin
    res = filtertokens(["a", "President.", "Robert,"])
    @test sort(res) == sort(["a", "president", "robert"])
end # @testset "filtertokens"

@testset "FilteredNGramDocument from string and other docs" begin
    d = FilteredNGramDocument("a President, Robert, a Swedish programmer.")
    ng = ngrams(d)
    @test sort(collect(keys(ng))) == sort(AbstractString["a", ",", ".", 
        "president", "robert", "swedish", "programmer"])
    @test ng["a"] == 2
    @test ng["president"] == 1
    @test ng["robert"] == 1
    @test ng["swedish"] == 1
    @test ng["programmer"] == 1
    @test ng["."] == 1
    @test ng[","] == 2

    d2 = FilteredNGramDocument(TokenDocument(["a", "President", "Robert", "a", "Swedish", "programmer"]))
    ng2 = ngrams(d2)
    @test sort(collect(keys(ng2))) == sort(AbstractString["a", "president", "robert", "swedish", "programmer"])
    @test ng2["a"] == 2

    ExampleFile = joinpath(dirname(@__FILE__()), "data", "example_with_strange_tokens.txt")
    d3 = FilteredNGramDocument(FileDocument(ExampleFile))
    @test sort(collect(keys(ngrams(d3)))) == sort(AbstractString["1", "2", "parl", "was", "modern", "1,2", "arne", ".", "best", "an", "success", "reported", "to", "sloan", "interpretative", "is", "mo", "and", "software", "sandor", "large-scale", "study", "methods", ":", "june", "development", "lea", "on", "abstract", "involvement", "adaptations", "coordination", "printed", "companies", "not", "guaranteed", "but", "for", "very", ",", "tory", "paper", "customer", "case", "co-located", "findings", "suit", "believed", "areas", "are", "done", "small", "at", "one", "imploring", "&", "it", "ebbe", "key", "nor", "the", "archi", "1977", "ro", "good", "3"])
end # @testset "FilteredNGramDocument from string"

@testset "FilteredNGramDocument document distance" begin
    wmd = WordMoversDistance()
    ws1 = ["obama", "speaks", "media", "illinois"]
    d1 = FilteredNGramDocument(join(ws1, " "), wmd)
    ws2 = ["president", "greets", "press", "chicago"]
    d2 = FilteredNGramDocument(join(ws2, " "), wmd)
    @test evaluate(wmd, d1, d2) == evaluate(wmd, ws1, ws2)
end # @testset "FilteredNGramDocument doc distance"

end