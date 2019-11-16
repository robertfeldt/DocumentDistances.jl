# Just a simpler API to WMD. Calls down to SinkhornDocDistance and uses
# GloVe for embeddings.
struct WordMoversDistance <: AbstractDocumentDistance
    sdist::SinkhornDocumentDistance
end

function WordMoversDistance()
    wdc = WordDistanceCache(".", :glove)
    WordMoversDistance(SinkhornDocumentDistance(wdc; rounds = 25))
end

import Distances.evaluate
evaluate(wmd::WordMoversDistance, d1, d2) = evaluate(wmd.sdist, d1, d2)

hasembedding(dd::AbstractDocumentDistance, word::AbstractString) =
    hasembedding(worddistance(dd), word)

worddistance(wmd::WordMoversDistance) = worddistance(wmd.sdist)