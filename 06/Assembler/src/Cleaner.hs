{-|
Module responsible for cleaning the raw input stream
-}

module Cleaner (
    cleanLine
) where

import Data.List.Utils (replace)
import Flow
import Text.Regex.Posix



cleanLine :: String -> String
cleanLine line =
    line
    |> removeNewlineChar
    |> removeInlineComment
    |> stripWhitespace


stripWhitespace :: String -> String
stripWhitespace =
    replace " " ""


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


isCommentLine :: String -> Bool
isCommentLine line =
    line =~ "^//" :: Bool


isBlankLine :: String -> Bool
isBlankLine line =
    (line =~ "^\r" :: Bool) || null line
