# Since it takes so long time to load the Embeddings we will instead cache
# calculated word distances so we only need to add the embeddings lazily, i.e.
# when the distance is needed to a new word.
vocabulary2indices(embtable) = Dict(word=>ii for (ii,word) in enumerate(embtable.vocab))

const DefaultWordCacheFilename = ".word_distances_cache.json"
const DefaultEmbeddingSystem = :word2vec
const DefaultEmbeddingFilenumber = 1

# We use our own mapping from embedding system names so users need not
# learn about the insides of the Embeddings package.
const GloVeLangFiles = language_files(GloVe{:en})
gloveindex(filename) = findfirst(f -> f == filename, GloVeLangFiles)

const EmbeddingName2Embedding = Dict(
    :word2vec      => (Embeddings.Word2Vec, 1),
    :glove         => (Embeddings.GloVe{:en}, gloveindex("glove.6B/glove.6B.300d.txt")),

    :glove6b50d    => (Embeddings.GloVe{:en}, gloveindex("glove.6B/glove.6B.50d.txt")),
    :glove6b100d   => (Embeddings.GloVe{:en}, gloveindex("glove.6B/glove.6B.100d.txt")),
    :glove6b200d   => (Embeddings.GloVe{:en}, gloveindex("glove.6B/glove.6B.200d.txt")),
    :glove6b300d   => (Embeddings.GloVe{:en}, gloveindex("glove.6B/glove.6B.300d.txt")),

    :glove42b300d  => (Embeddings.GloVe{:en}, gloveindex("glove.42B.300d/glove.42B.300d.txt")),
    :glove840b300d => (Embeddings.GloVe{:en}, gloveindex("glove.840B.300d/glove.840B.300d.txt")),
)

embeddingname2embedding(name) = lookup_embeddingname(Symbol(lowercase(string(name))))

function lookup_embeddingname(name::Symbol)
    try
        return EmbeddingName2Embedding[name]
    catch err
        allembeddings = join(map(string, collect(keys(EmbeddingName2Embedding))), ", ")
        error("Cannot find an embedding for $name.\nAvailable embeddings: $allembeddings")
    end
end

# We cache embeddings and their word indices also so we need not load 
# and calc them multiple times.
const EmbeddingsCache = Dict()

function cache_load_embeddings(embsys, embfilenumber)
    if !haskey(EmbeddingsCache, (embsys, embfilenumber))
        println("Loading the embeddings for ($embsys, $embfilenumber). This often can take 20-60 seconds...")
        embtable = load_embeddings(embsys, embfilenumber)
        wordindex = vocabulary2indices(embtable)
        EmbeddingsCache[(embsys, embfilenumber)] = (embtable, wordindex)
    end
    EmbeddingsCache[(embsys, embfilenumber)]
end

mutable struct WordDistanceCache
    dirname::String
    cachefile::String
    embeddingsystem::Symbol
    embtable::Union{Embeddings.EmbeddingTable, Nothing}
    wordindex::Dict{String, Int}
    worddistances::Dict{Tuple{String,String}, Float64}

    WordDistanceCache(dir::String, embeddingsystem::Symbol; 
        cachefile = DefaultWordCacheFilename) = begin
        new(dir, cachefile, embeddingsystem,
            nothing,
            Dict{String, Int}(),
            Dict{Tuple{String,String}, Float64}())
    end
end

function WordDistanceCache(cachefilepath::String)
    isfile(cachefilepath) && return load_word_distance_cache(cachefilepath)
    error("No cache file found at $fn")
end

function load_embeddings!(wdc::WordDistanceCache)
    if wdc.embtable == nothing
        embsys, embfilenum = embeddingname2embedding(wdc.embeddingsystem)
        wdc.embtable, wdc.wordindex = cache_load_embeddings(embsys, embfilenum)
    end
end

function worddistance(wdc::WordDistanceCache, w1::String, w2::String)
    get!(wdc.worddistances, (w1, w2)) do
        calcworddistance(wdc, w1, w2)
    end
end

const EmbeddingDistance = Euclidean()

function calcworddistance(wdc::WordDistanceCache, w1::String, w2::String)
    evaluate(EmbeddingDistance, embedding(wdc, w1), embedding(wdc, w2)) 
end

function embedding(wdc::WordDistanceCache, w::String)
    wdc.embtable != nothing || load_embeddings!(wdc)
    try
        ind = wdc.wordindex[w]
        return wdc.embtable.embeddings[:,ind]
    catch err
        # Very strange but "and" is not available in Word2Vec while "And" is. Maybe
        # we want to fix this?
        error("No embedding found for word $w")
    end
end

# This is for when we load from json only...
function add_distance!(wdc::WordDistanceCache, w1::String, w2::String, d::Number)
    wdc.worddistances[(w1, w2)] = Float64(d)
end

# When saving to json we must output distances in an array so we don't
# lose its structure. JSON cannot handle Julia tuples.
function distances_as_array_for_json(wdc::WordDistanceCache)
    Any[Any[w1, w2, d] for ((w1, w2), d) in wdc.worddistances]
end

import JSON.json
function json(wdc::WordDistanceCache)
    metadict = Dict(
        "embeddingsystem" => string(wdc.embeddingsystem),
        "lastsave" => Libc.strftime("%Y-%m-%d %H:%M.%S", time())
    )
    js = json(Dict("meta" => metadict, "distances" => distances_as_array_for_json(wdc)), 2)
    return js
end

function save(wdc::WordDistanceCache)
    fn = joinpath(wdc.dirname, wdc.cachefile)
    open(fn, "w") do fh
        println(fh, json(wdc))
    end
    println("Cached word distance cache to $fn")
end

function load_word_distance_cache(cachefilepath::String)
    d = JSON.parse(read(cachefilepath, String))
    println("Reading word distance cache that was last saved: ", d["meta"]["lastsave"])

    cachefile = last(split(cachefilepath, "/"))
    embeddingsystem = Symbol(get(d["meta"], "embeddingsystem", "Word2Vec"))
    wdc = WordDistanceCache(dirname(cachefilepath), embeddingsystem;
        cachefile = cachefile)

    # In json the distances are saved as arrays [word1, word2, dist] so we add them
    # manually based on that.
    for entry in d["distances"]
        add_distance!(wdc, entry[1], entry[2], entry[3])
    end

    return wdc
end
