using DocumentDistances: pdf2text, withtxtext, walkfilesmatching

const ExampleFileDir = joinpath(dirname(@__FILE__()), "data", "pdffile")
const ExamplePdfFile = joinpath(ExampleFileDir, "testfile.pdf")
const ExampleTxtFile = joinpath(ExampleFileDir, "testfile.txt")

@testset "withtxtext" begin
    @test withtxtext("test.pdf") == "test.txt"
    @test withtxtext("/my/path/test_123.pdf") == "/my/path/test_123.txt"
end # @testset "withtxtext"

@testset "pdf2text" begin
    isfile(ExampleTxtFile) && rm(ExampleTxtFile)
    txtfilename = pdf2text(ExamplePdfFile)
    @test txtfilename == ExampleTxtFile
    @test isfile(ExampleTxtFile)
    isfile(ExampleTxtFile) && rm(ExampleTxtFile) # Clean up again after us
end # @testset "pdf2text"

@testset "walkfilesmatching" begin
    pdfs = String[]
    walkfilesmatching(fp -> push!(pdfs, fp), ExampleFileDir, r"\.pdf$")
    @test length(pdfs) == 1
end # @testset "pdf2text"