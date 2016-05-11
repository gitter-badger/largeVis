largeVis
================

This is an implementation of the `largeVis` algorithm described in (<https://arxiv.org/abs/1602.00370>). It also incorporates code for a very fast algorithm for estimating k-nearest neighbors.

The inner loops for nearest-neighbor search and gradient descent are implemented in C++ using `Rcpp` and `RcppArmadillo`. (If you get an error that a `NULL value passed as symbol address` this relates to `Rcpp` and please open an issue here.)

This has been tested and confirmed to work in many circumstances. More extensive documentation and examples are being prepared.

Please note that this package is under development (the paper is only two weeks old) so it is likely that implementation bugs will be found and changes made to the api.

Some notes:

-   There may be a bug in one of the gradients.
-   This implementation uses C++ implementations of the most computationally intensive phases: exploring the random projection trees, neighborhood exploration, calculating *p*<sub>*j*|*i*</sub>, and the final calculation of the embeddings using sgd. The implementation will attempt to use OpenMP if it is available.
-   The sigma-estimation phase is implemented with `mclapply` from the `parallel` package. The number of cores that will be used may be set with `options(mc.cores = n)`

Examples:
---------

``` r
library(largeVis)
library(ggplot2)
data(iris)
dat <- as.matrix(iris[,1:4])
coords <- largeVis(dat, pca.first = F, 
                   max.iter = 5, sgd.batches = 2000000, 
                   gamma = 7, K = 40, M = 5, rho = 2,min.rho = 0, verbose = FALSE)
coords <- data.frame(coords$coords)
colnames(coords) <- c("X", "Y")
coords$Species <- iris$Species
ggplot(coords, aes(x = X, y = Y, color = Species)) + geom_point(size = 0.5)
```
