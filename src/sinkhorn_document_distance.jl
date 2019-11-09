using Embeddings
using Distances
using SinkhornDistance

const EmbTableWord2Vec = load_embeddings(Word2Vec) # or load_embeddings(FastText_Text) or ...

# Takes 54 sec to load! Maybe we should cache the word distances instead???
#const EmbTableGloVe6B300d = load_embeddings(GloVe{:en}, 4)
# Takes 33 sec to load
#@time const EmbTableGloVe6B200d = load_embeddings(GloVe{:en}, 3)

vocabulary2indices(embtable) = Dict(word=>ii for (ii,word) in enumerate(embtable.vocab))

function marginals_from_doc(doc::Vector{String}, corpus::Vector{String})
    N = length(corpus)
    counts = zeros(Int, N)
    for d in doc
        idx = findfirst(wi -> d == corpus[wi], 1:N)
        counts[idx] += 1
    end
    freqs = counts ./ sum(counts)
end

struct SinkhornDocumentDistance{E,D}
    rounds::Int
    embtable::E
    embeddingdistance::D
    wordindex::Dict{String, Int}
    worddistances::Dict{Tuple{String,String}, Float64} # We cache distances so we need to recalc them
end

function SinkhornDocumentDistance(e::E = EmbTableGloVe6B200d, d::D = Euclidean();
    rounds = 100) where {D <: Distances.PreMetric, E <: Embeddings.EmbeddingTable}

    wordindex = vocabulary2indices(e)
    worddistances = Dict{Tuple{String,String}, Float64}()
    SinkhornDocumentDistance{E,D}(rounds, e, d, wordindex, worddistances)
end

function worddistance(sdd::SinkhornDocumentDistance, w1::String, w2::String)
    get!(sdd.worddistances, (w1, w2)) do
        calcworddistance(sdd, w1, w2)
    end
end

function calcworddistance(sdd::SinkhornDocumentDistance, w1::String, w2::String)
    evaluate(sdd.embeddingdistance, embedding(sdd, w1), embedding(sdd, w2)) 
end

function embedding(sdd::SinkhornDocumentDistance, w::String)
    ind = sdd.wordindex[w]
    return sdd.embtable.embeddings[:,ind]
end

function distancematrix(sdd::SinkhornDocumentDistance, allwords::Vector{String})
    N = length(allwords)
    dmatrix = zeros(Float64, N, N)
    for i in 1:N
        w1 = allwords[i]
        for j in (i+1):N
            w2 = allwords[j]
            dmatrix[i, j] = dmatrix[j, i] = worddistance(sdd, w1, w2)
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
    m1 = marginals_from_doc(d1l, allwords)
    m2 = marginals_from_doc(d2l, allwords)
    # We might want to use sparse vectors for the marginals but maybe not since we have a restricted corpus here which only are the words in these two docs.
    #pl = sinkhorn_plan(dmatrix, sparsevec(m1), sparsevec(m2); rounds = rounds)
    pl = sinkhorn_plan(dmatrix, m1, m2; rounds = rounds)
    cost = sum(dmatrix .* pl)
    return cost, pl
end

import Distances.evaluate
function evaluate(sdd::SinkhornDocumentDistance, d1::Vector{String}, d2::Vector{String}; rounds = sdd.rounds)
    first(calculate(sdd, d1, d2; rounds = rounds))
end
