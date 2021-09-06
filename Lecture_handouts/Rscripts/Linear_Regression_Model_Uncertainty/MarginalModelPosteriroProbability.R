# --------------------------------------------------------------------------------
#   
#   Copyright 2019 Georgios Karagiannis
#
# georgios.karagiannis@durham.ac.uk 
# Assistant Professor 
# Department of Mathematical Sciences, Durham University, Durham,  UK 
# 
# This file is part of Bayesian_Statistics (MATH3341/4031 Bayesian Statistics III/IV)
# which is the material of the course (MATH3341/4031 Bayesian Statistics III/IV)
# taught by Georgios P. Katagiannis in the Department of Mathematical Sciences
# in the University of Durham  in Michaelmas term in 2019
# 
# Bayesian_Statistics is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation version 3 of the License.
# 
# Bayesian_Statistics is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bayesian_Statistics  If not, see <http://www.gnu.org/licenses/>.
# 
# --------------------------------------------------------------------------------

# clean the mess

rm(list=ls())


# MODEL AND EQUATIONS


comp_sufficient_stats <- function (y, X) {

  n <- dim(X)[1]
  
  d <- dim(X)[2]
  
  XtX <- t(X)%*%X
  
  XtY <- t(X)%*%y
  
  YtY <- sum(y*y)
  
  return( list(XtX=XtX, XtY=XtY, YtY=YtY, n=n, d=d) )
}

comp_V_post <- function (y, X, V_prior) {
    
  sufficient_stats <- comp_sufficient_stats(y, X)
  
  XtX <- sufficient_stats$XtX
  
  V_post <- solve( XtX + solve(V_prior) ) 
  
  return (V_post)
}

comp_mu_post <- function (y, X, mu_prior, V_prior, a_prior, lam_prior) {
  
  sufficient_stats <- comp_sufficient_stats(y, X)
  
  XtX <- sufficient_stats$XtX
  
  XtY <- sufficient_stats$XtY
  
  mu_post <- comp_V_post( y, X, V_prior) %*% ( solve( V_prior , mu_prior ) + XtY )
  
  return (mu_post)
}


comp_a_post <- function ( y, X,  a_prior) {
  
  sufficient_stats <- comp_sufficient_stats(y, X)
  
  n <- sufficient_stats$n
  
  a_post <- 0.5*n + a_prior
  
  return (a_post)
}

comp_lam_post <- function (y, X, mu_prior, V_prior, a_prior, lam_prior) {
  
  sufficient_stats <- comp_sufficient_stats(y, X)
  
  YtY <- sufficient_stats$YtY
  
  V_post <- comp_V_post(y, X, V_prior)

  mu_post <- comp_mu_post(y, X, mu_prior, V_prior, a_prior, lam_prior)
  
  S <- sum(mu_prior * solve(V_prior,mu_prior)) 

  S <- S -sum(mu_post * solve(V_post, mu_post))
  
  S <- S + YtY
  
  lam_post <- 0.5*S + lam_prior
  
  return (lam_post)
}


comp_cond_likel <- function(y, X, mu_prior, V_prior, a_prior, lam_prior) {
  
  sufficient_stats <- comp_sufficient_stats(y, X)
  
  n <- sufficient_stats$n
  
  YtY <- sufficient_stats$YtY
  
  a_post <- comp_a_post( y, X,  a_prior)
  
  lam_post <- comp_lam_post(y, X, mu_prior, V_prior, a_prior, lam_prior)
  
  V_post <- comp_V_post(y, X, V_prior)
  
  cond_likel <- (0.5*pi)^(n/2) 
  
  cond_likel <- cond_likel * sqrt(det(V_post)) 
  
  cond_likel <- cond_likel / sqrt(det(V_prior))
  
  cond_likel <- cond_likel * (lam_prior)^(a_prior)
  
  cond_likel <- cond_likel / (lam_post)^(a_post)
  
  cond_likel <- cond_likel * gamma(a_post)
  
  cond_likel <- cond_likel / gamma(a_prior)
  
  return (cond_likel)
}

comp_margimal_model_posterior_prob <-function(y, X__all, 
                                              mu_prior_all, V_prior_all, a_prior_all, lam_prior_all,
                                              Available_models,
                                              marginal_model_prior) {
    

  K_size <- length(Available_models)
  
  margimal_model_posterior_prob <- matrix(rep(0.0, length.out=K_size), K_size)
  
  for (i in 1:K_size) {
        
    k <- Available_models[[i]]
    
    margimal_model_prior_k <- marginal_model_prior[i]
    
    X_k <- X_all[[i]]
    
    mu_prior_k <- mu_prior_all[[i]]
    if ( length(mu_prior_k[[1]])>1)  mu_prior_k <- mu_prior_k[[1]][1,]
    
    V_prior_k <- V_prior_all[[i]]
    
    a_prior_k <- a_prior_all[[i]]
    
    lam_prior_k <- lam_prior_all[[i]]
    
    
    sufficient_stats <- comp_sufficient_stats( y, X_k )
    
    d <- sufficient_stats$d
    
    margimal_model_posterior_prob[i] <- comp_cond_likel(y, X_k, 
                                                        mu_prior_k, 
                                                     V_prior_k, 
                                                     a_prior_k, 
                                                     lam_prior_k)*margimal_model_prior_k
  }
  
  margimal_model_posterior_prob <- margimal_model_posterior_prob/sum(margimal_model_posterior_prob)
}
    
    
    





comp_Bayes_factor <- function(y, X0, mu_prior0, V_prior0, a_prior0, lam_prior0,
                     X1, mu_prior1, V_prior1, a_prior1, lam_prior1) {
  
  cond_likel_0 <- comp_cond_likel(y, X0, mu_prior0, V_prior0, a_prior0, lam_prior0)
  
  cond_likel_1 <- comp_cond_likel(y, X1, mu_prior1, V_prior1, a_prior1, lam_prior1)
  
  Bayes_factor <- cond_likel_0 / cond_likel_1
  
  return(Bayes_factor)
}


## Observables

data(airquality)

airquality_na.omit <- na.omit(airquality)

y = airquality_na.omit$Ozone

X_full = cbind( rep(1,length(y)), 
           airquality_na.omit$Solar.R, 
           airquality_na.omit$Wind, 
           airquality_na.omit$Temp)
#standardise
X_full[,-1] <- scale(X_full[,-1])

## COmposite model

# MODELS

Available_models <- list (M0 = c(1),
                         M1 = c(1,2),
                         M2 = c(1,3),
                         M3 = c(1,4),
                         M4 = c(1,2,3),
                         M5 = c(1,2,4),
                         M6 = c(1,3,4),
                         M7 = c(1,2,3,4)
)



size_K <- length(Available_models) 

for (i in 1:size_K) {
  
  n <- length( y )
  
  temp <- comp_sufficient_stats(y, matrix( X_full[,Available_models[[i]]] , n ) )
  
  if (i == 1) {
    
    X_all <- list ( matrix( X_full[,Available_models[[i]]] , n ))
    
    
  } else {
    
    X_all[[i]] <-  matrix( X_full[,Available_models[[i]]] , n )
  }
}


## Prior model

size_K <- length(Available_models) 

marginal_model_prior <- rep (NaN , size_K )


for (i in 1:size_K) {
  marginal_model_prior[i] <- 1/ size_K
}



for (i in 1:size_K) {
  
  n <- length( y )
  
  d <- length(Available_models[[i]] )

  if (i == 1) {
    
    mu_prior_all <- list ( matrix(rep(0, d ), 1, d ) )
    
    V_prior_all <- list ( diag(rep(100, length.out=d),nrow=d) )
    
    a_prior_all <- list ( 1.0 )
    
    lam_prior_all <- list ( 1.0 )
    
     
  } else {
    
    mu_prior_all[[i]] <- list ( matrix(rep(0, d), 1, d) )
    
    V_prior_all[[i]] <- diag(rep(100, length.out=d),nrow=d)
    
    a_prior_all[[i]] <-  1.0 
    
    lam_prior_all[[i]] <-  1.0 
    
  }
  
}

# PLOT THE MARGINAL MODEL POSTERIRO PROBABILITY

margimal_model_posterior_prob<- comp_margimal_model_posterior_prob(y, X_all, 
                                                                  mu_prior_all, 
                                                                  V_prior_all, 
                                                                  a_prior_all, 
                                                                  lam_prior_all,
                                                                  Available_models,
                                                                  marginal_model_prior)



# PLOT THE MARGINAL MODEL POSTERIRO PROBABILITY AND THE INDIVIDUAL Y ~ X_j SCATERPLOTS

par( mfrow=c(2,3)  )
for ( j in 2:4) plot(X_full[,j],y, ylab = 'y', xlab =  paste('X_',toString(j)))
barplot( t(marginal_model_prior), 
         names.arg=c('M0','M1','M2','M3','M4','M5','M6','M7'),
         ylab = 'Prob',
         xlab = 'Competing models',
         main = 'Marginal model prior probabilities',
         ylim = c(0,1)
)
barplot( t(margimal_model_posterior_prob), 
        names.arg=c('M0','M1','M2','M3','M4','M5','M6','M7'),
        ylab = 'Prob',
        xlab = 'Competing models',
        main = 'Marginal model posterior probabilities',
        ylim = c(0,1)
)



# Print me on pdf
for ( j in 2:4) 
{
  pdf(paste('./airquality',as.character(j),'.pdf'))
  plot(X_full[,j],y, ylab = 'y', xlab =  paste('X_',toString(j)))
  dev.off() 
}
j = j+1
pdf(paste('./airquality',as.character(j),'.pdf'))
barplot( t(margimal_model_posterior_prob), 
         names.arg=c('M0','M1','M2','M3','M4','M5','M6','M7'),
         ylab = 'Prob',
         xlab = 'Competing models',
         main = 'Marginal model posterior probabilities',
         ylim = c(0,1)
)
dev.off() 
j = j+1
pdf(paste('./airquality',as.character(j),'.pdf'))
barplot( t(marginal_model_prior), 
         names.arg=c('M0','M1','M2','M3','M4','M5','M6','M7'),
         ylab = 'Prob',
         xlab = 'Competing models',
         main = 'Marginal model prior probabilities',
         ylim = c(0,1)
)
dev.off() 




