# DocumentDistances.jl

Calculate distances (metrics) between documents based on word embeddings. 

The basic approach is to use word embeddings and the Word Mover's Distance (WMD) to calculate distances between documents. Currently it uses sinkhorn distance to approximate the optimal transport between documents. This is known to be an accurate approximation although it has
quadratic computational compelxity. Thus, currently, this package might not be well suited
for distance calculation for very long documents.

This is primarily a julia package but can also be used from docker.
