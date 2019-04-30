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
    deriving (Show)


newtype Destination
    = Destination String
    deriving (Show)


newtype Computation 
    = Computation String
    deriving (Show)


newtype Jump
    = Jump String
    deriving (Show)


data Command
    = AInstruction Address
    | CInstruction Computation (Maybe Destination) (Maybe Jump)
    | PseudoCommand String
    | UnrecognisedCommand String
    deriving (Show)



-- FUNCTIONS



parse :: [String] -> [String]
parse lines =
    lines
    |> Cleaner.clean
    |> map parseLine
    |> map printCommand


printCommand :: Command -> String
printCommand command =
    case command of
        UnrecognisedCommand rawCommand ->
            "UNRECOGNISED: \"" ++ rawCommand ++ "\""

        _ ->
            show command


parseLine :: String -> Command
parseLine line
    | isPseudoCommand line = parsePseudoCommand line
    | isAInstruction line = parseAInstruction line
    | isCInstruction line = parseCInstruction line
    | otherwise = UnrecognisedCommand line


isPseudoCommand :: String -> Bool
isPseudoCommand line =
    line =~ "^\\(.+\\)$" :: Bool


parsePseudoCommand :: String -> Command
parsePseudoCommand line =
    let
        (_, _, firstParenRemoved) = line =~ "^\\(" :: (String, String, String)
        (symbol, _, _) = firstParenRemoved =~ "\\)$" :: (String, String, String)
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
            Just exactAddress ->
                ExactAddress exactAddress

            Nothing ->
                AddressSymbol rawAddressString
    in
        AInstruction address



isCInstruction :: String -> Bool
isCInstruction line =
    line =~ "^(0|D|A|M)?(;|=)?(.+)$" :: Bool


parseCInstruction :: String -> Command
parseCInstruction line =
    let
        maybeJump = getJump line

        maybeDestination = getDestination line

        maybeComputation = getComputation line
    in
        case maybeComputation of
            Just computation ->
                CInstruction computation maybeDestination maybeJump

            Nothing ->
                UnrecognisedCommand line


getComputation :: String -> Maybe Computation
getComputation line =
    let
        (_, _, matchWithEquals) = line =~ "=" :: (String, String, String)
        (_, _, matchWithSemicolon) = line =~ ";" :: (String, String, String)

        match =
            if length matchWithEquals > 0 then
                matchWithEquals
            else
                matchWithSemicolon
        
        hasComputation =
            not (null match)
    in
        if hasComputation then
            Just (Computation match)
        else
            Nothing


getDestination :: String -> Maybe Destination
getDestination line =
    let
        (_, match, _) = line =~ "^(M|D|MD|A|AM|AD|AMD)=" :: (String, String, String)

        destinationString =
            if not (null match) then
                init match
            else
                ""
        
        hasDestination =
            not (null destinationString)
    in
        if hasDestination then
            Just (Destination destinationString)
        else
            Nothing



getJump :: String -> Maybe Jump
getJump line =
    let
        (_, match, _) = line =~ ";(JGT|JEQ|JGE|JLT|JNE|JLE|JMP)$" :: (String, String, String)
        
        jumpString =
            if (length match) > 0 then
                tail match
            else
                ""
        
        hasJump =
            not (null jumpString)
    in
        if hasJump then Just (Jump jumpString) else Nothing