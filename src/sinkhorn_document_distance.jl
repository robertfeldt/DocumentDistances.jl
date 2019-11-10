using SparseArrays

function marginals_from_doc(doc::Vector{String}, vocabulary::Vector{String};
    usesparse = true)

    N = length(vocabulary)
    counts = usesparse ? spzeros(N) : zeros(Float64, N)
    for d in doc
        idx = findfirst(wi -> d == vocabulary[wi], 1:N)
        counts[idx] += 1
    end
    freqs = counts ./ sum(counts)
    return freqs
end

struct SinkhornDocumentDistance
    usesparse::Bool # If we should use sparse calculations (of the marginals)
    rounds::Int
    worddistancecache::WordDistanceCache
end

function SinkhornDocumentDistance(embeddingName::Symbol = :glove;
    dir::String = ".", rounds::Int = 100, usesparse = true)
    wdc = WordDistanceCache(dir, embeddingName)
    SinkhornDocumentDistance(usesparse, rounds, wdc)
end

function distancematrix(sdd::SinkhornDocumentDistance, allwords::Vector{String})
    N = length(allwords)
    dmatrix = zeros(Float64, N, N)
    for i in 1:N
        w1 = allwords[i]
        for j in (i+1):N
            w2 = allwords[j]
            dmatrix[i, j] = dmatrix[j, i] = worddistance(sdd.worddistancecache, w1, w2)
        end
    end
    return dmatrix
end

# Calculate the document distance between two documents, represented as vectors of strings.
# Returns the distance, i.e. the cost of transport from one to the other, and the plan with transfer values.
function calculate(sdd::SinkhornDocumentDistance, d1::Vector{String}, d2::Vector{String}; 
    rounds = sdd.rounds)

    d1l = map(lowercase, d1)
    d2l = map(lowercase, d2)
    allwords = unique(vcat(d1l, d2l))
    dmatrix = distancematrix(sdd, allwords)
    m1 = marginals_from_doc(d1l, allwords; usesparse = sdd.usesparse)
    m2 = marginals_from_doc(d2l, allwords; usesparse = sdd.usesparse)
    pl = sinkhorn_plan(dmatrix, m1, m2; rounds = rounds)
    cost = sum(dmatrix .* pl)
    return cost, pl
end

import Distances.evaluate
function evaluate(sdd::SinkhornDocumentDistance, d1::Vector{String}, d2::Vector{String}; rounds = sdd.rounds)
    first(calculate(sdd, d1, d2; rounds = rounds))
end
