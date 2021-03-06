

#' Project a distance matrix into a lower-dimensional space.
#'
#' The input is a sparse triplet matrix showing the weights to give the edges, which are presumably estimated
#' k-nearest-neighbors.
#'
#' The algorithm attempts to estimate a \code{dim}-dimensional embedding using stochastic gradient descent and
#' negative sampling.
#'
#' The objective function is: \deqn{ O = \sum_{(i,j)\in E} w_{ij} (\log f(||p(e_{ij} = 1||) + \sum_{k=1}^{M} E_{jk~P_{n}(j)} \gamma \log(1 - f(||p(e_{ij_k} - 1||)))}
#' where \eqn{f()} is a probabilistic function relating the distance between two points in the low-dimensional projection space,
#' and the probability that they are nearest neighbors.  See the discussion of the alpha parameter below.
#'
#' The \code{weight_pos_samples} parameter controls how to handle edge-weights.  The paper authors recommend using a weighted
#' sampling approach to select edges, and treating edge-weight as binary in calculating the objective. This is the default.
#'
#' However, the algorithm for drawing weighted samples runs in \eqn{O(n *\log n)}. The alternative approach, which runs in
#' \eqn{O(n)}, is to draw unweighted samples and include \eqn{w_{ij}} in the objective function.
#'
#' @param wij A sparse matrix of edge weights.
#' @param dim The number of dimensions for the projection space.
#' @param sgd_batches The number of edges to process during SGD; defaults to 20000 * the number of rows in x, as recommended
#' by the paper authors.
#' @param M The number of negative edges to sample for each positive edge.
#' @param alpha Hyperparameter used in the default distance function, \eqn{1 / (1 + \alpha \dot ||y_i - y_j||^2)}.  If \code{alpha} is 0, the alternative distance
#' function \eqn{1 / 1 + exp(||y_i - y_j||^2)} is used instead.  These functions relate the distance between points in the low-dimensional projection to the likelihood
#' that they two points are nearest neighbors. Note: the alternative probabilistic distance function is not yet implemented.
#' @param gamma Hyperparameter analogous to the strength of the force operating to push-away negative examples.
#' @param weight_pos_samples Whether to sample positive edges according to their edge weights (the default) or take the
#' weights into account when calculating gradient.  See also the Details section.
#' @param rho Initial learning rate.
#' @param min_rho Final learning rate.
#' @param coords An initialized coordinate matrix.
#' @param verbose Verbosity
#'
#' @return A dense [nrow(x),dim] matrix of the coordinates projecting x into the lower-dimensional space.
#' @export
#' @importFrom stats rnorm
#'

projectKNNs <- function(wij, # sparse matrix
                        dim = 2, # dimension of the projection space
                        sgd_batches = nrow(N) * 20000,
                        M = 5,
                        weight_pos_samples = TRUE,
                        gamma = 7,
                        alpha = 2,
                        rho = 1,
                        coords = NULL,
                        min_rho = 0.1,
                        verbose = TRUE) {
  N <- length(wij@p) - 1
  js <- rep(0:(N-1), diff(wij@p))
  is <- wij@i

  ##############################################
  # Initialize coordinate matrix
  ##############################################
  if (is.null(coords)) coords <- matrix(rnorm(N * dim), ncol = dim)

  #################################################
  # SGD
  #################################################
  callback <- function(tick, tokens) {}
  progress <- #utils::txtProgressBar(min = 0, max = sgd_batches, style = 3)
    progress::progress_bar$new(total = sgd_batches, format = 'SGD [:bar] :percent :elapsed/:eta Training Loss: :loss', clear=FALSE)
  if (verbose[1]) callback <- progress$tick
  callback(0, -Inf)
  sgd(coords,
              is = is,
              js = js,
              ps = wij@p,
              ws = wij@x,
              gamma = gamma, rho = rho, minRho = min_rho,
              useWeights = ! weight_pos_samples, nBatches = sgd_batches,
              M = M, alpha = alpha, callback = callback)

  return(coords)
}
