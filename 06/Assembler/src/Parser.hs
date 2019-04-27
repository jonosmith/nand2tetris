{-|
Parses the input into a structured format
-}
module Parser (
    parse
) where

import qualified Cleaner
import Flow
import Text.Read
import Text.Regex.Posix


-- TYPES

data CommandType
    = A
    | C
    | PSEUDO

data Address
    = ExactAddress Int
    | AddressSymbol String


data Destination = Destination String
data Computation = Computation String
data Jump = Jump String

data Command
    = AInstruction Address
    | CInstruction Computation (Maybe Destination) (Maybe Jump)
    | PseudoCommand String
    | UnrecognisedCommand String

-- MAIN

parse :: [String] -> [String]
parse lines =
    lines
    |> Cleaner.clean
    |> map parseLine
    |> map printCommand


printCommand :: Command -> String
printCommand command =
    case command of
        AInstruction address -> printAddress address
        -- CInstruction _ _ _ -> print
        _ -> "unrecognised"


printAddress :: Address -> String
printAddress address =
    case address of
        ExactAddress exactAddress -> "Address (exact):" ++ show exactAddress
        AddressSymbol symbol -> "Address (symbol):" ++ symbol


parseLine :: String -> Command
parseLine line
    | isPseudoCommand line = parsePseudoCommand line
    | isAInstruction line = parseAInstruction line
    | otherwise = UnrecognisedCommand line



isPseudoCommand :: String -> Bool
isPseudoCommand line =
    line =~ "^\\(.+\\)$" :: Bool


parsePseudoCommand :: String -> Command
parsePseudoCommand line =
    let
        (_, _, firstParenRemoved) = line =~ "^\\(" :: (String, String, String)
        (symbol, _, _) = line =~ "\\)$" :: (String, String, String)
    in
        PseudoCommand symbol


isAInstruction :: String -> Bool
isAInstruction line =
    line =~ "^@" :: Bool


parseAInstruction :: String -> Command
parseAInstruction line =
    let
        (_, _, rawAddressString) = line =~ "^@" :: (String, String, String)

        maybeExactAddress = readMaybe rawAddressString :: Maybe Int

        address = case maybeExactAddress of
            Just exactAddress -> ExactAddress exactAddress
            Nothing -> AddressSymbol rawAddressString
    in
        AInstruction address