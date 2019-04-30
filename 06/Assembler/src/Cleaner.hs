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
    |> stripNewlines
    |> removeBlankLines


stripWhitespace :: [String] -> [String]
stripWhitespace =
    map (replace " " "")


stripNewlines :: [String] -> [String]
stripNewlines =
    map removeNewlineChar


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


removeNewlineChar :: String -> String
removeNewlineChar line =
    let
        (before, _, _) = line =~ "\r" :: (String, String, String)
    in
        before


removeBlankLines :: [String] -> [String]
removeBlankLines =
    filter (\line -> not (isBlankLine line))


isCommentLine :: String -> Bool
isCommentLine line =
    line =~ "^//" :: Bool


isBlankLine :: String -> Bool
isBlankLine line =
    (line =~ "^\r" :: Bool) || (null line)
