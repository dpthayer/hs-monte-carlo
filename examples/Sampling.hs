module Main
    where

import Control.Monad.MC
import Control.Monad
import Data.List( foldl' )
import System.Environment( getArgs )
import Text.Printf( printf )


-- | Sample from a binomial distribution with the given parameters.
binomial :: (MonadMC m) => Int -> Double -> m Int
binomial n p = let
    q     = 1 - p
    probs = map (\i -> (fromIntegral $ n `choose` i) * p^^i * q^^(n-i)) [0..n]
    in sampleIntWithWeights probs (n+1)

-- | Get a sample confidence interval for the mean after @reps@ replications of
-- a binomial with the given parameters.
binomialMean :: (MonadMC m) => Int -> Double -> Int -> m (Double,Double)
binomialMean n p reps =
    liftM (sampleCI 0.95) $ replicateMC reps $ liftM fromIntegral (binomial n p)

-- | Compute @reps@ 95% confidence intervals for the mean of an @(n,p)@
-- binormal based on samples of the given size, and record the number
-- of intervals that contain the true mean.
coverage :: (MonadMC m) => Int -> Double -> Int -> Int -> m Int
coverage n p size reps =
    replicateMCWith
        (\c ci -> if mu `inInterval` ci then c+1 else c)
        0
        reps
        (binomialMean n p size)
  where
    mu = fromIntegral n * p
    x `inInterval` (l,h) = x > l && x < h

main = do
    [reps] <- map read `fmap` getArgs
    main' reps

main' reps =
    let seed = 0
        n    = 10
        p    = 0.2
        size = 500
        c    = evalMC (coverage n p size reps) $ mt19937 seed in
    printf "\nOf %d 95%%-intervals, %d contain the true value.\n" reps c


---------------------------   Utility functions -----------------------------

factorial :: Int -> Int
factorial n | n <= 0    = 1
            | otherwise = n * factorial (n-1)

choose :: Int -> Int -> Int
choose n k = factorial n `div` (factorial (n-k) * factorial k)
