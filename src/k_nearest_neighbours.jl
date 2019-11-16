# Find the <k> nearest neighbour documents in <corpus> for <doc>.
function find_k_nearest_neighbours(dist::AbstractDocumentDistance, corpus, doc; k = 10)
    @assert k >= 1
    withdistances = map(cdoc -> (cdoc, evaluate(dist, cdoc, doc)), corpus)
    sort!(withdistances, by = t -> t[2])
    return withdistances[1:min(k, length(withdistances))]
end
