@testset "WordMoversDistance" begin

# Just a stress test of the more abstract interface.
wmd = WordMoversDistance()
d1 = ["obama", "speaks", "media", "illinois"]
d2 = ["president", "greets", "press", "chicago"]
d12 = evaluate(wmd, d1, d2)
d3 = ["lawyer", "tanks", "car", "africa"]
d13 = evaluate(wmd, d1, d3)
d23 = evaluate(wmd, d2, d3)
@test d12 < d13
@test d12 < d23

end