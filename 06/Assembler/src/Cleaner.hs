{-|
Module responsible for cleaning the raw input stream
-}

module Cleaner (
    clean
) where

import Text.Regex.Posix
import Flow
import Data.List.Utils (replace)


clean :: [String] -> [String]
clean lines =
    lines
    |> stripWhitespace
    |> stripComments
    |> removeBlankLines


stripWhitespace :: [String] -> [String]
stripWhitespace lines =
    map (\line -> replace " " "" line) lines


stripComments :: [String] -> [String]
stripComments lines =
    let
        removedCommentLines = filter (\line -> not (isCommentLine line)) lines
        
        removedInlineComments = 
            map removeInlineComment removedCommentLines
    in
        removedInlineComments


removeInlineComment :: String -> String
removeInlineComment line =
    let
        (beforeComment, _, _) = line =~ "//" :: (String, String, String)
    in
        beforeComment


removeBlankLines :: [String] -> [String]
removeBlankLines lines =
    filter (\line -> not (isBlankLine line)) lines


isCommentLine :: String -> Bool
isCommentLine line =
    line =~ "^//" :: Bool


isBlankLine :: String -> Bool
isBlankLine line =
    line =~ "^\r" :: Bool
