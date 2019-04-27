module Main where

-- import Lib
import System.Environment
import System.IO
import Prelude
import Data.Foldable
import Parser


main :: IO ()
main = do
    args <- getArgs
    case args of
        [] -> error "Usage: Assembler \"path/to/file\""
        [arg] -> do
            handle <- openFile arg ReadMode

            rawLines <- fmap lines (hGetContents handle)

            let parsed = Parser.parse rawLines

            forM_ parsed $ \line -> putStrLn line

        _ -> error "Too many arguments"



