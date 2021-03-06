
module Main where

import Debug.Trace
import Control.Monad
import Data.AEq
import Data.List
import System.IO
import System.Environment
import System.Random
import Text.Printf
import Test.QuickCheck
import Test.Framework
import Test.Framework.Providers.QuickCheck2

import Control.Monad.MC.Walker


prop_table_probs (Weights n ws) =
    let table = computeTable n ws
    in all (\i -> probOf table i ~== ps !! i) [0..n-1]
  where
    ps = probsFromWeights ws

prop_table_index (Weights n ws) (Unif u) =
    let table = computeTable n ws
        i     = indexTable table u
    in i >= 0 && i < n && (ws !! i > 0)

tests_Walker = testGroup "Walker"
    [ testProperty "table probabilities" prop_table_probs
    , testProperty "table indexing"      prop_table_index
    ]

probOf table i =
    (((sum . map ((1-) . fst) . filter ((==i) . snd))
                       (map (component table) [0..n-1]))
                       + (fst . component table) i) / fromIntegral n
  where
    n = tableSize table

------------------------------- Utility functions ---------------------------

probsFromWeights ws = let
    w  = sum ws
    ps = map (/w) ws
    in ps

------------------------------- Test generators -----------------------------

posInt :: Gen Int
posInt = do
    n <- arbitrary
    return $! abs n + 1

weight :: Gen Double
weight = do
    w <- liftM abs arbitrary
    if w < infty then return w else weight
  where
    infty = 1/0

weights :: Int -> Gen [Double]
weights n = do
    ws <- replicateM n weight
    if not (all (== 0) ws) then return ws else return $ replicate n 1.0

unif :: Gen Double
unif = do
    u <- choose (0,1)
    if u == 1 then return 0 else return u

data Weights = Weights Int [Double] deriving Show
instance Arbitrary Weights where
    arbitrary = do
        n  <- choose (1, 500)
        ws <- weights n
        return $ Weights n ws

data Unif = Unif Double deriving Show
instance Arbitrary Unif where
    arbitrary            = liftM Unif unif


main :: IO ()
main = defaultMain [ tests_Walker ]
