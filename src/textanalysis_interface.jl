# Make our document distances work with the TextAnalysis package

const DefaultDocDistance = WordMoversDistance()

# Find the closest token with an embedding in a DocDistance. If the
# token itself has no embedding we will try to "clean" it until we find
# an embedding which is likely to carry very similar meaning.
function findclosetoken(t::String, dd::AbstractDocumentDistance = DefaultDocDistance;
    skipdot = true, skiphyphen = true, skipcomma = true, makelowercase = true)
    hasembedding(dd, t) && return(t)
    if (skipdot && endswith(t, ".")) || (skiphyphen && endswith(t, "-")) ||
        (skipcomma && endswith(t, ","))
        t = t[1:prevind(t, length(t), 1)]
        hasembedding(dd, t) && return(t)
    end
    if makelowercase
        t = lowercase(t)
    end
    # Return nothing to indicate we couldn't find a close token with an embedding
    return hasembedding(dd, t) ? t : nothing
end

# Filter the tokens of a Document so we keep only the ones that have an embedding.
# We try some simple transformations before we give up on finding an embedding.
function filtertokens(tokens, dd::AbstractDocumentDistance = DefaultDocDistance;
    skipdot = true, skiphyphen = true, skipcomma = true, makelowercase = true)
    res = String[]
    for t in tokens
        t2 = findclosetoken(t, dd; skipdot = skipdot, skiphyphen = skiphyphen, skipcomma = skipcomma, makelowercase = makelowercase)
        if !isnothing(t2)
            push!(res, t2)
        end
    end
    return res
end

# Rather than filter tokens every time we want to calculate the doc distance
# we can pre-filter and cache the ngrams and then more quickly calculate
# the distance.
mutable struct FilteredNGramDocument <: AbstractDocument
    ngramdoc::NGramDocument # NGramDoc where only the filtered/transformed tokens are left
    metadata::TextAnalysis.DocumentMetadata
end

import TextAnalysis.ngrams
ngrams(d::FilteredNGramDocument) = ngrams(d.ngramdoc)

function FilteredNGramDocument(d::AbstractDocument, dd::AbstractDocumentDistance = DefaultDocDistance)
    ftoks = filtertokens(tokens(d), dd)
    ngd = NGramDocument(TextAnalysis.ngramize(d.metadata.language, ftoks, 1), 1)
    FilteredNGramDocument(ngd, d.metadata)
end

FilteredNGramDocument(s::AbstractString, dd::AbstractDocumentDistance = DefaultDocDistance) =
    FilteredNGramDocument(StringDocument(s), dd)

function FilteredNGramDocument(d::NGramDocument, dd::AbstractDocumentDistance = DefaultDocDistance)
    toks = keys(ngrams(d))
    ftoks = filtertokens(toks, dd)
    ngd = NGramDocument(ftoks, 1)
    FilteredNGramDocument(ngd, s.metadata)
end
    
# Quicker calculation of the marginals and vocabulary since we already have the counts.
function marginals_and_vocabulary(d1::FilteredNGramDocument, d2::FilteredNGramDocument; usesparse = true)
    v = make_vocabulary()
    k1 = keys(d1.ngramdoc.ngrams)
    k2 = keys(d2.ngramdoc.ngrams)
    update_vocabulary!(v, k1)
    update_vocabulary!(v, k2)
    m1 = calc_marginal(d1, k1, v; usesparse = usesparse)
    m2 = calc_marginal(d2, k2, v; usesparse = usesparse)
    return m1, m2, v
end

# Quicker calculation of the marginals since we already have the counts.
function calc_marginal(doc::FilteredNGramDocument, ks::Base.KeySet, vocabulary::AbstractDict{T, V}; usesparse = true) where {T<:AbstractString, V<:Integer}
    N, counts = makecountvector(vocabulary, usesparse)
    for k in ks
        if haskey(vocabulary, k)
            idx = vocabulary[k]
            counts[idx] += doc.ngramdoc[k]
        end
    end
    return frequencies_from_counts(counts)
end

# Find all pdf files (recursively) in a dir, convert them to text files, then read
# in a corpus representing them. Iff onlyifnew is true then convert to text file
# only if the pdf file is newer than the text file.
#function pdf_directory_corpus(dirname::String; 
#    recursive = true, onlyifnew = true, wordDistance = WordDistanceCache(),
#    ngramdocs = true)
#    txtfiles = convert_pdf_files_to_txt(dirname; recursive = recursive, onlyifnew = onlyifnew)
#    docs = map(fp -> EmbeddedTokensFileDocument(fp, wordDistance), txtfiles)
#    if ngramdocs
#        docs = map(NGramDocument, docs)
#    end
#    return Corpus(docs)
#end