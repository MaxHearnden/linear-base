{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Simple.Quicksort
  ( testQuicksort
  , quickSort
  )
where

import GHC.Stack
import qualified Data.Array.Mutable.Linear as Array
import Data.Array.Mutable.Linear (Array)
import Data.Unrestricted.Linear
import Prelude.Linear hiding (partition)


-- # Testing
-------------------------------------------------------------------------------

testQuicksort :: [Int] -> Bool
testQuicksort xs = sort xs == quickSort xs


-- # Quicksort
-------------------------------------------------------------------------------

quickSort :: [Int] -> [Int]
quickSort xs = unur $ Array.fromList xs $ Array.toList . arrQuicksort

arrQuicksort :: Array Int %1-> Array Int
arrQuicksort arr = Array.size arr &
  \(Ur len, arr1) -> go 0 (len-1) arr1

go :: Int -> Int -> Array Int %1-> Array Int
go lo hi arr
  | lo >= hi = arr
  | otherwise = Array.read arr lo &
    \(Ur pivot, arr1) -> partition arr1 pivot lo hi &
      \(arr2, Ur ix) -> swap arr2 lo ix &
        \arr3 -> go lo (ix-1) arr3 &
          \arr4 -> go (ix+1) hi arr4

partition :: Array Int %1-> Int -> Int -> Int -> (Array Int, Ur Int)
partition arr pivot lx rx
  | (rx < lx) = (arr, Ur (lx-1))
  | otherwise = Array.read arr lx &
      \(Ur lVal, arr1) -> Array.read arr1 rx &
        \(Ur rVal, arr2) -> case (lVal <= pivot, pivot < rVal) of
          (True, True) -> partition arr2 pivot (lx+1) (rx-1)
          (True, False) -> partition arr2 pivot (lx+1) rx
          (False, True) -> partition arr2 pivot lx (rx-1)
          (False, False) -> swap arr2 lx rx &
            \arr3 -> partition arr3 pivot (lx+1) (rx-1)

swap :: HasCallStack => Array Int %1-> Int -> Int -> Array Int
swap arr i j = Array.read arr i &
  \(Ur ival, arr1) -> Array.read arr1 j &
    \(Ur jval, arr2) -> (Array.set i jval . Array.set j ival) arr2
