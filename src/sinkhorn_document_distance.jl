frequencies_from_counts(cs::AbstractVector{N}) where {N<:Number} = 
    cs ./ Float64(sum(cs))

function makecountvector(vocabulary, usesparse = true)
    N = length(vocabulary)
    return (N, usesparse ? spzeros(Int, N) : zeros(Int, N))
end

function update_vocabulary!(vocab::AbstractDict{T,Int}, words::Vector{T}) where {T<:AbstractString}
    idx = length(vocab)
    for w in words
        !haskey(vocab, w) && (vocab[w] = (idx += 1))
    end
    return vocab
end

make_vocabulary(words::Vector{T}) where {T<:AbstractString} = 
    update_vocabulary!(Dict{T, Int}(), words)

function calc_marginal(doc::Vector{T}, vocabulary::AbstractDict{T, V}; usesparse = true) where {T<:AbstractString, V<:Integer}
    N, counts = makecountvector(vocabulary, usesparse)
    for d in doc
        if haskey(vocabulary, d)
            idx = vocabulary[d]
            counts[idx] += 1
        end
    end
    return frequencies_from_counts(counts)
end

# For testing purposes we allow also a vector vocab...
function calc_marginal(doc::Vector{T}, vocabulary::Vector{T}; usesparse = true) where {T<:AbstractString}
    calc_marginal(doc, make_vocabulary(vocabulary); usesparse = usesparse)
end

function marginals_and_vocabulary(d1::Vector{T}, d2::Vector{T}; usesparse = true) where {T<:AbstractString}
    v = make_vocabulary(d1)
    update_vocabulary!(v, d2)
    m1 = calc_marginal(d1, v; usesparse = usesparse)
    m2 = calc_marginal(d2, v; usesparse = usesparse)
    return m1, m2, v
end

struct SinkhornDocumentDistance
    usesparse::Bool # If we should use sparse calculations (of the marginals)
    rounds::Int
    worddistancecache::WordDistanceCache
end

function SinkhornDocumentDistance(embeddingName::Symbol = :word2vec;
    dir::String = ".", rounds::Int = 100, usesparse = true)
    wdc = WordDistanceCache(dir, embeddingName)
    SinkhornDocumentDistance(usesparse, rounds, wdc)
end

function SinkhornDocumentDistance(wdc::WordDistanceCache;
    rounds::Int = 100, usesparse = true)
    SinkhornDocumentDistance(usesparse, rounds, wdc)
end

function distancematrix(sdd::SinkhornDocumentDistance, vocabulary::AbstractDict{T, V}) where {T<:AbstractString,V}
    N = length(vocabulary)
    dmatrix = zeros(Float64, N, N)
    vocabwords = collect(keys(vocabulary))
    for i in 1:N
        w1 = vocabwords[i]
        for j in (i+1):N
            w2 = vocabwords[j]
            dmatrix[i, j] = dmatrix[j, i] = worddistance(sdd.worddistancecache, w1, w2)
        end
    end
    return dmatrix
end

# Redefine this for other types for which you want to be able to calculate Sinkhorn distance.
words(d::Vector{T}) where {T<:AbstractString} = d

function marginals_and_vocabulary(sdd::SinkhornDocumentDistance, d1, d2)
    marginals_and_vocabulary(words(d1), words(d2); usesparse = sdd.usesparse)
end

# Calculate the document distance between two documents, represented as vectors of strings.
# Returns the distance, i.e. the cost of transport from one to the other, and the plan with transfer values.
function calculate(sdd::SinkhornDocumentDistance, d1, d2)
    m1, m2, vocab = marginals_and_vocabulary(sdd, d1, d2)
    return cost_and_plan(sdd, m1, m2, vocab)
end

function cost_and_plan(sdd::SinkhornDocumentDistance, m1, m2, vocab)
    distmatrix = distancematrix(sdd, vocab)
    pl = sinkhorn_plan(distmatrix, m1, m2; rounds = sdd.rounds)
    cost = sum(distmatrix .* pl)
    return cost, pl
end

import Distances.evaluate
function evaluate(sdd::SinkhornDocumentDistance, d1, d2)
    first(calculate(sdd, d1, d2))
end
