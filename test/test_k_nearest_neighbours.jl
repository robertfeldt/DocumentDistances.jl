@testset "find_k_nearest_neighbours" begin

wmd = WordMoversDistance()
d1 = ["obama", "speaks", "media", "illinois"]
d2 = ["president", "greets", "press", "chicago"]
d3 = ["lawyer", "tanks", "car", "africa"]

corpus = [d1, d3]
top1 = find_k_nearest_neighbours(wmd, corpus, d2; k = 1)
@test length(top1) == 1
@test first(top1[1]) == d1 # d2 is closer to d1 than to d3
@test top1[1][2] == evaluate(wmd, d1, d2)

top2 = find_k_nearest_neighbours(wmd, corpus, d2; k = 2)
@test length(top2) == 2
@test first(top2[1]) == d1
@test top2[1][2] == evaluate(wmd, d1, d2)
@test first(top2[2]) == d3
@test top2[2][2] == evaluate(wmd, d3, d2)

top5 = find_k_nearest_neighbours(wmd, corpus, d2; k = 5)
@test length(top5) == 2 # Only two docs available
@test first(top5[1]) == d1
@test first(top5[2]) == d3

end