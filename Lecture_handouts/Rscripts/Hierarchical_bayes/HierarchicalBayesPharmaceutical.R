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



rm(list=ls())

# Load rjags
library("rjags") 

hierarhicalmodel <- "

  model {
    
    for ( i in 1 : I ) {
    
      for ( j in 1 : J ) { 
      
      x[i,j] ~ dnorm( theta[i] , tau_c  )
      
      y[i,j] ~ dnorm( theta[i] + delta[i] , tau_a  )
      
      z[i,j] ~ dnorm( theta[i] + delta[i] + xi[i] , tau_t  )
      
      }
      
      theta[i] ~ dnorm( mu_theta , tau_theta  )
      
      delta[i] ~ dnorm( mu_delta , tau_delta  )
      
      w_ind[i] <- ifelse(w[i] == 0, 0, 1)
      xi[i] <- w_ind[i]*x_d +(1-w_ind[i])*x_p
    }
    
      sig2_c <- 1/tau_c
      tau_c ~ dgamma(0.01 , 0.01)
      
      sig2_a = 1/tau_a
      tau_a ~ dgamma(0.01 , 0.01)
      
      sig2_t <- 1/tau_t
      tau_t ~ dgamma(0.01 , 0.01)
      
      mu_theta ~ dnorm( 0 , 0.001 )
      sig2_theta = 1/tau_theta
      tau_theta ~ dgamma(0.01 , 0.01)
      
      mu_delta ~ dnorm( 0 , 0.001 )
      sig2_delta <- 1/tau_delta
      tau_delta ~ dgamma(0.01 , 0.01)
      
      x_p ~ dnorm( mu_p , tau_p  )
      x_d ~ dnorm( mu_d , tau_d  )
      
      mu_p ~ dnorm( 0 , 0.001 )
      sig2_p <- 1/tau_p
      tau_p ~ dgamma(0.01 , 0.01)
      
      mu_d ~ dnorm( 0 , 0.001 )
      sig2_d <- 1/tau_d
      tau_d ~ dgamma(0.01 , 0.01)
  }

"


# data

I_obs <- 31

J_obs <- J_a <- J_c <- J_t <- 5

mu_th <- 1.63 # this is what I wich to estimate 

mu_del <- -2.82 # this is what I wich to estimate

mu_p <- 0.53 # this is what I wich to estimate

mu_d <- 1.39 # this is what I wich to estimate

x_obs <- matrix(rnorm(I_obs*J_obs, mu_th, sqrt( 0.25 ) ), I_obs, J_obs)

y_obs <- matrix(rnorm(I_obs*J_obs, mu_th +mu_del, sqrt( 0.25 +0.25 +0.25 ) ), I_obs, J_obs)

w_obs <- c(rep(0,16),rep(1,I_obs-16))

z_obs <- matrix(rep(NaN,I_obs*J_obs), I_obs, J_obs)

for (i in 1:I_obs) {
  if ( w_obs[i]==0 ){
    z_obs[i,] <- rnorm(J_obs, mu_th +mu_del +mu_p, sqrt( 0.25 +0.25 +0.25 +0.15 ) )
  } else if ( w_obs[i]==1 ){
    z_obs[i,] <- rnorm(J_obs, mu_th +mu_del +mu_d, sqrt( 0.25 +0.25 +0.25 +0.15 ) )
  }  
}

data.bayes <- list(y = y_obs,
                   x = x_obs,
                   z = z_obs,
                   w = w_obs,
                   I = I_obs,
                   J = J_obs)



# Create an input list, for jags, containing the data and fixed parameters of the model

model.smpl <- jags.model( file = textConnection(hierarhicalmodel),
                          data = data.bayes)

# Initialize the sampler

adapt(object = model.smpl, 
      n.iter = 10^5)

# Generate a posterior sample of size ...

N = 10^4      # the size of the sample we ll gona get
n.thin = 10^1     # the thining (improving) the sample quality
n.iter = N * n.thin # the number of the total iterations performed
output = jags.samples( model = model.smpl,          # the model
                       variable.names = c("mu_theta", "mu_delta", "mu_p", "mu_d"),    # names of variables to be sampled
                       n.iter = n.iter,               # size of sample
                       thin = n.thin,
)
save.image(file="HierarchicalBayesPharmaceutical.RData") 


mu_theta.smpl <- output$mu_theta
mu_delta.smpl <- output$mu_delta
mu_p.smpl <- output$mu_p
mu_d.smpl <- output$mu_d

# plot the traces
par(mfrow=c(2,2))
z <- mu_theta.smpl[1,,]
plot(z,
     type = "l",
     main = "Trace plot of mu_theta",
     xlab = "iteration", 
     ylab ="mu_theta"
)
z <- mu_delta.smpl[1,,]
plot(z,
     type = "l",
     main = "Trace plot of mu_delta",
     xlab = "iteration", 
     ylab ="mu_delta"
)
z <- mu_p.smpl[1,,]
plot(z,
     type = "l",
     main = "Trace plot of mu_p",
     xlab = "iteration", 
     ylab ="mu_p"
)
z <- mu_d.smpl[1,,]
plot(z,
     type = "l",
     main = "Trace plot of mu_d",
     xlab = "iteration", 
     ylab ="mu_d"
)


# plot the histograms
par(mfrow=c(2,2))
z <- mu_theta.smpl[1,,]
hist(z, 
     main = "Histogram of mu_theta",
     xlab = "iteration", 
     ylab ="mu_theta"
)
z <- mu_delta.smpl[1,,]
hist(z, 
     main = "Histogram of mu_delta", 
     xlab ="mu_delta"
)
z <- mu_p.smpl[1,,]
hist(z, 
     main = "Histogram of mu_p", 
     xlab ="mu_p"
)
z <- mu_d.smpl[1,,]
hist(z, 
     main = "Histogram of mu_d", 
     xlab ="mu_d"
)

# point estimates


mean(mu_theta.smpl)
mean(mu_delta.smpl)
mean(mu_p.smpl)
mean(mu_d.smpl)

# recall that :
#
# mu_th <- 1.63   
#
# mu_del <- -2.82  
#
# mu_p <- 0.53  
#
# mu_d <- 1.39  




