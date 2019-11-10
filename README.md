# DocumentDistances.jl

Calculate distances (metrics) between words and documents based on word embeddings.

The basic approach is to use word embeddings and the Word Mover's Distance (WMD) to calculate distances between documents. We first map the words in a document to their embeddings, can calculate word distances by using regular vector distances between the embeddings, and then use WMD to calculate the optimal transport plan to go from one document to the other.

Currently we use [Sinkhorn distance](https://arxiv.org/abs/1306.0895) to approximate the optimal transport plan between documents. This is known to be an accurate approximation although it has quadratic computational compelxity. Thus, currently, this package might not be well suited for distance calculation for very long documents.

This is primarily a Julia package but can also be used as a binary directly from a Docker image.

## Installation

Ensure you have added SinkhornDistance and then add DocumentDistances:

```julia
]add https://github.com/currymj/SinkhornDistance.jl.git
]add https://github.com/robertfeldt/DocumentDistances.jl
```

from the Julia repl. 

Note that loading this package takes some time since it, in turn, loads the `Embeddings` package (which takes 20-60 seconds to load, typically).

## Usage

Let's recreate the simple, illustrating example from the [paper](http://www.jmlr.org/proceedings/papers/v37/kusnerb15.pdf) that introduced the Word Mover's Distance (WMD). We have two documents (here they are just short 4-word sentences) that are semantically similar but syntactically very different (since they have no words in common):
```julia
doc1 = ["obama", "speaks", "media", "illinois"]
doc2 = ["president", "greets", "press", "chicago"]
```
To calculate their distance we create a distance and call evaluate on it:
```julia
using DocumentDistances
sdd = SinkhornDocumentDistance()
d12 = evaluate(sdd, doc1, doc2) # return WMD between documents, is ~6.71 when I test this
```
Note that the first time you call this it will take a long time to execute since it loads the word embeddings from disk (or potentially downloads them from the Internet which takes even longer).

To see if the returned distance is reasonable let's compare to another document that we expect to be further from the two documents above:
```julia
doc3 = ["lawyer", "tanks", "car", "africa"]
d13 = evaluate(sdd, doc1, doc3) # ~8.83 for me
d23 = evaluate(sdd, doc2, doc3) # ~8.79 for me
@assert d12 < d13
@assert d12 < d23
```
If we only want to calculate distances between individual words we can instead use a WordDistanceCache directly:
```julia
wdc = WordDistanceCache()
d1 = worddistance(wdc, "robert", "programmer") # ~1.34
d2 = worddistance(wdc, "robert", "astronaut")  # ~1.42
@assert d1 < d2 # Apparently Robert is closer to a programmer than an astronaut :)
```
This cache can be saved to disk for speedier access to the same distances later (note that there is no loading of embeddings at this point):
```julia
save(wdc) # This is saved to ./.word_distances_cache.json as default but you can change this in the constructor
wdc2 = WordDistanceCache("./.word_distances_cache.json")
worddistance(wdc2, "robert", "programmer") == d1
```

## Background and relevant papers

For more on the Sinkhorn distance see:
- [Original paper by Cuturi](https://arxiv.org/abs/1306.0895) on applying this to EMD: Cuturi (2013), "Sinkhorn Distances: Lightspeed Computation of Optimal Transportation Distances", NeurIPS.

We use the excellent [SinkhornDistance.jl](https://github.com/currymj/SinkhornDistance.jl) by Michael J. Curry for the Julia implementation.

The well-known paper that proposed to use the Earth Mover's Distance (EMD) as a document distance, i.e. Word Mover's Distance (WMD):
- M. Kusner, Y. Sun, N. Kolkin, and K. Weinberger (2015), "[From word embeddings to document distances](http://www.jmlr.org/proceedings/papers/v37/kusnerb15.pdf)". In International Conference on Machine Learning, pp. 957-966.

For our word embeddings we use the excellent [Embeddings.jl](https://github.com/JuliaText/Embeddings.jl) by Lyndon White and the [JuliaText](https://github.com/JuliaText) team. 