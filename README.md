# DocumentDistances.jl

Calculate distances (metrics) between documents based on word embeddings. 

The basic approach is to use word embeddings and the Word Mover's Distance (WMD) to calculate distances between documents. Currently it uses [Sinkhorn distance](https://arxiv.org/abs/1306.0895) to approximate the optimal transport between documents. This is known to be an accurate approximation although it has
quadratic computational compelxity. Thus, currently, this package might not be well suited
for distance calculation for very long documents.

This is primarily a julia package but can also be used from docker.

## Related papers

For more on the Sinkhorn distance see:
- [Original paper by Cuturi](https://arxiv.org/abs/1306.0895) on applying this to EMD: Cuturi (2013), "Sinkhorn Distances: Lightspeed Computation of Optimal Transportation Distances", NeurIPS.

We use the excellent [SinkhornDistance.jl](https://github.com/currymj/SinkhornDistance.jl) by Michael J. curry for the Julia implementation.

The well-known paper that proposed to use the Earth Mover's Distance (EMD) as a document distance, i.e. Word Mover's Distance (WMD):
- M. Kusner, Y. Sun, N. Kolkin, and K. Weinberger (2015), "[From word embeddings to document distances](http://www.jmlr.org/proceedings/papers/v37/kusnerb15.pdf)". In International Conference on Machine Learning, pp. 957-966.