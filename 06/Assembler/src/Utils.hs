module Utils (
    intToBinaryOfLength
) where

import Numeric (showHex, showIntAtBase)
import Data.Char (intToDigit)
import Flow


{-| Converts a number to a binary string of the given length

Example:
-- >>> intToBinaryOfLength 16 5
-- "0000000000000101"
-}
intToBinaryOfLength :: Int -> Int -> String
intToBinaryOfLength maxLength number =
    leftPadBinaryTo maxLength (intToBinary number)
    |> reverse
    |> take maxLength
    |> reverse



intToBinary :: Int -> String
intToBinary number =
    showIntAtBase 2 intToDigit number ""


leftPadBinaryTo :: Int -> String -> String
leftPadBinaryTo size binaryString =
    (\x -> replicate (size - length binaryString) '0' ++ x) binaryString
