rm( list = ls() )  

library(gtools)

#install.packages('invgamma')

library('invgamma')

# get the data 

# from the computer practical:  
# http://htmlpreview.github.io/?https://github.com/georgios-stats/Bayesian_Statistics_Michaelmas_2021/blob/main/Computer_practical/Normal_Mixture_model/Bayesian_Normal_Mixture_Model.nb.html
#mydata <- scan('https://raw.githubusercontent.com/georgios-stats/Bayesian_Statistics_Michaelmas_2021/main/Computer_practical/Normal_Mixture_model/enz.dat')
#y <- mydata
#n <- length(y)


n <- 500 

w_real <- c(0.3, 0.2, 0.5) 
mu_real <- c(5, 10, 20)
sigma2_real <- c(0.1, 0.5, 1)

y <- c()
for (i in 1:n)
{
  u <- runif(n=1)
  if (u < sum(w_real[1]) )
  {
    yi <- rnorm(n=1, mean=mu_real[1], sd=sqrt(sigma2_real[1]) )
  }
  else if (u < sum(w_real[1:2]) )
  {
    yi <- rnorm(n=1, mean=mu_real[2], sd = sqrt(sigma2_real[2]) )
  }
  else
  {
    yi <- rnorm(n=1, mean=mu_real[3], sd = sqrt(sigma2_real[3]) )
  }
  y <- c(y, yi)  
}


# plot observations
fntsz <- 1.5
hist(y,
     freq = FALSE,
     breaks = 12,
     main = ' ',
     xlab = 'values', 
     ylab = 'pdf estimation', 
     cex.lab=fntsz, 
     cex.axis=fntsz, 
     cex.main=fntsz, 
     cex.sub=fntsz)

# number of components
k = 3

# fixed parameters

delta <- 1

xi <- mean(y)

kappa <- 1/range(y)^2

alpha <- 2.0

he = 10.0/range(y)^2

ge = 0.2 

# seed

k = 3

w = c(1/3,1/3,1-1/3-1/3) 

mu = mu_real #c(0.2,1.0,1.6) 

sigma2 = c(1,1,1) 

beta = 1.0

z = sample.int(3, size = n, replace = TRUE) 

# mcmc parameters

num_mcmc_burn_in <- 0

num_mcmc_iter <- 10000

# working vectors

w_chain <- matrix(rep(NaN,k*num_mcmc_iter),num_mcmc_iter,k)

mu_chain <- matrix(rep(NaN,k*num_mcmc_iter),num_mcmc_iter,k)

sigma2_chain <- matrix(rep(NaN,k*num_mcmc_iter),num_mcmc_iter,k)

beta_chain <- matrix(rep(NaN,1*num_mcmc_iter),num_mcmc_iter,1)

z_chain <- matrix(rep(NaN,n*num_mcmc_iter),num_mcmc_iter,n)

# mcmc scan

for ( it in num_mcmc_burn_in:num_mcmc_iter) 
{
  
  #
  # update w
  #
  
  w <- rdirichlet(n=1, 
                  alpha = c( sum(z==1)+delta, sum(z==2)+delta, sum(z==3)+delta  ) 
  ) 
  
  #
  # update mu, sigma
  #
  
  for (j in 1:k)
  {
    sigma2[j] <- rinvgamma(n = 1, 
                           shape = alpha+0.5*sum(z==j), 
                           rate = beta + 0.5*sum( (z==j)*((y-mu[j])^2) ) 
    )
    
    mu[j] <- rnorm(n=1, 
                   mean=(sum((z==j)*y)+xi*kappa) / (sum(z==j)+kappa), 
                   sd = sqrt( sigma2[j]/ (sum(z==j)+kappa) )
    )
  }
  
  #
  # update z
  #
  
  for (i in 1:n)
  {
    pr <- w * dnorm(y[i], mean = mu, sd = sqrt( sigma2 ), log = FALSE)
    
    pr <- pr / sum( pr )
    
    z[i] <- sample.int(k, size = 1, replace = FALSE, prob = pr)
  }
  
  #
  # update beta 
  #
  
  beta <- rgamma(n = 1, shape = ge +k*alpha , he+sum(1/sigma2)  )
  
  #
  # update labels by MH with a proposal distribution a random permutation
  #
  
  ind <- sample.int(k) 
  
  w <- w[ind]
  
  mu <- mu[ind]
  
  sigma2 <- sigma2[ind]
  
  for (i in 1:n)
  {
    z[i] = match( z[i] , ind)
  }
  
  #
  # store
  #
  
  if ( it >= 1 )
  {
    w_chain[ it,] = w
    
    mu_chain[ it,] <- mu
    
    sigma2_chain[ it,] <- sigma2
    
    z_chain[ it,] <- z
    
    beta_chain[ it] <- beta 
  }
}


# #####################
# ESTIMATE THE PDF
# #####################

# pdf of sampling distribution
fmix <- function(y, varpi, mu, sigma) {
  f <- sum( varpi*dnorm(y, mean = mu, sd = sigma) ) ;
  return ( f  )
}


# set the horizontal axis values
ynew_min = 0.0
ynew_max = max(y)+1
ynew_size = 100
ynew = seq(from = ynew_min, to = ynew_max, length.out = ynew_size) 
# compute the estimates at ynew
fest_mean = rep(NaN, times = ynew_size)
fest_low = rep(NaN, times = ynew_size)
fest_upper = rep(NaN, times = ynew_size)
Nsample <- num_mcmc_iter
vec <- rep(NaN, times = Nsample)
for (i in 1: length(ynew)) {
  for (t in 1:Nsample) {
    vec[t] <- fmix(ynew[i], w_chain[t,], mu_chain[t,], sqrt(sigma2_chain[t]) )
  }
  fest_low[i] <-  quantile(vec, probs = 0.025)
  fest_upper[i] <-  quantile(vec, probs = 0.975)
  fest_mean[i] <- mean(vec)
}
# print the prediction and the predictive intervals
fntsz <- 1.5
plot(ynew,
     fest_mean,
     main = "predictive distribution",
     xlab = "enzyme",
     ylab = "pdf",
     type = 'l',
     col = 'black',
     cex.lab=fntsz, 
     cex.axis=fntsz, 
     cex.main=fntsz, 
     cex.sub=fntsz
)
lines (ynew,
       fest_low,
       col = 'blue'
)
lines (ynew,
       fest_upper,
       col = 'blue'
)

# #####################
# TRACE PLOTS OF MU
# #####################

x = mu_chain

plot(x[,1],
     type='l',
     col=1, 
     ylim = c(min(x), max(x)),
     main='trace plot of mu' )

for (j in 2:k)
{
  lines(mu_chain[,j],col=j)
}

# ########################
# HISTOGRAM PLOTS OF MU[1]
# ########################

x = mu_chain

par(mfrow=c(k,1))
for ( j in 1:k )
{
  hist(x[,j], main='hist of mu' )
}






