@testset "README examples" begin

sdd = SinkhornDocumentDistance()

# From Kusner's WMD paper they used this illustrative example of two
# quite similar sentences (documents) which are similar semantically
# but not syntactically.
d1 = ["obama", "speaks", "media", "illinois"]
d2 = ["president", "greets", "press", "chicago"]
d12 = evaluate(sdd, d1, d2)

# To compare to something let's take a different document which we expect
# to have a larger distance to the ones above than they have to each other.
d3 = ["lawyer", "tanks", "car", "africa"]

d13 = evaluate(sdd, d1, d3)
d23 = evaluate(sdd, d2, d3)

@test d12 < d13
@test d12 < d23

wdc = WordDistanceCache()
d1 = worddistance(wdc, "robert", "programmer") # 
d2 = worddistance(wdc, "robert", "astronaut")
@test d1 < d2

end