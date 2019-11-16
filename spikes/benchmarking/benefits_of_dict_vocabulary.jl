frequencies_from_counts(cs::AbstractVector{N}) where {N<:Number} = 
    cs ./ Float64(sum(cs))

function makecountvector(vocabulary, usesparse = true)
    N = length(vocabulary)
    return (N, usesparse ? spzeros(N) : zeros(Float64, N))
end

function make_vector_vocabulary(d1::Vector{T}, d2::Vector{T}) where {T<:AbstractString}
    unique(vcat(d1, d2))
end

function make_dict_vocabulary(d1::Vector{T}, d2::Vector{T}) where {T<:AbstractString}
    v = Dict{T, Int}()
    idx = 0
    for d in d1
        !haskey(v, d) && (v[d] = (idx += 1))
    end
    for d in d2
        !haskey(v, d) && (v[d] = (idx += 1))
    end
    return v
end

function calc_marginal(doc::Vector{T}, vocabulary::Vector{T};
    usesparse = true)  where {T<:AbstractString}
    N, counts = makecountvector(vocabulary, usesparse)
    for d in doc
        idx = findfirst(wi -> d == vocabulary[wi], 1:N)
        if !isnothing(idx)
            counts[idx] += 1
        end
    end
    return frequencies_from_counts(counts)
end

function calc_marginal(doc::Vector{T}, vocabulary::AbstractDict{T, V};
    usesparse = true) where {T<:AbstractString, V<:Integer}
    N, counts = makecountvector(vocabulary, usesparse)
    for d in doc
        if haskey(vocabulary, d)
            idx = vocabulary[d]
            counts[idx] += 1
        end
    end
    return frequencies_from_counts(counts)
end

###############################################################################

using Random
N = 100
words = String[randstring(rand(1:5)) for _ in 1:N]
d1 = words[1:Int(N/2)]
d2 = words[Int(1+N/2):end]

using BenchmarkTools

# Vector or Dict vocabulary
@benchmark make_vector_vocabulary(d1, d2) # 9.0 microsec, +21.6%
@benchmark make_dict_vocabulary(d1, d2)   # 7.4 microsec
vv = make_vector_vocabulary(d1, d2)
dv = make_dict_vocabulary(d1, d2)
@benchmark calc_marginal(d1, vv)          # 8.8 microsec, +109.5%
@benchmark calc_marginal(d1, dv)          # 4.2 microsec

# Dict Vocabulary is faster even for short vocabs of 100 elements.

# 1000 words
N = 1000
words = String[randstring(rand(1:5)) for _ in 1:N]
d1 = words[1:Int(N/2)]
d2 = words[Int(1+N/2):end]
@benchmark make_dict_vocabulary(d1, d2)   # 92.8 microsec
@benchmark make_vector_vocabulary(d1, d2) # 102.2 microsec, +10.0%
vv = make_vector_vocabulary(d1, d2)
dv = make_dict_vocabulary(d1, d2)
@benchmark calc_marginal(d1, dv)          # 43.7 microsec
@benchmark calc_marginal(d1, vv)          # 525.9 microsec, +1103.4%

# As expected, it is much faster for larger vocabularies. This is a benefit
# if we will be reusing a vocabulary for many pair-wise comparisons.