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
import Common.Command
import SymbolTable (SymbolTable)
import qualified SymbolTable
import Data.Maybe
import Data.Sequence (foldlWithIndex, fromList)
import Data.Foldable (toList)
import Code


-- TYPES



data ParsedLine
    = ParsedLine
    { parsedLineResult :: LineResult
    , parsedLineNumber :: Int
    }


data LineResult
    = ValidCommand Command
    | UnrecognisedCommand String
    | NoCommand


newtype ParsedValidCommand =
    ParsedValidCommand Command


data ParseContext
    = ParseContext
    { parseContextOutputInstructions :: [String]
    , parseContextCurrentROMAddress :: Int
    , parseContextNextAvailableRAMAddress :: Int
    , parseContextSymbolTable :: SymbolTable
    }
    deriving (Show)



-- FUNCTIONS



parse :: [String] -> [String]
parse lines =
    let
        initParseContext =
            ParseContext
            { parseContextOutputInstructions = []
            , parseContextCurrentROMAddress = 0
            , parseContextNextAvailableRAMAddress = 16 -- Just after addresses for predefined symbols
            , parseContextSymbolTable = SymbolTable.makeNew
            }

        parsedLines =
            zip lines [1..]
                |> map parseLine


        validCommands =
            filterValidCommands parsedLines


        contextAfterFirstPass =
            firstPass validCommands initParseContext

        contextAfterSecondPass =
            secondPass validCommands contextAfterFirstPass

    in
        [show contextAfterSecondPass]



filterValidCommands :: [ParsedLine] -> [ParsedValidCommand]
filterValidCommands parsedLines =
    mapMaybe getValidCommand parsedLines


getValidCommand :: ParsedLine -> Maybe ParsedValidCommand
getValidCommand parsedLine =
    case parsedLineResult parsedLine of
        ValidCommand command ->
            Just $ ParsedValidCommand command

        _ ->
            Nothing


-- FIRST PASS


{-| First pass to build up the symbol table with any encountered pseudo commands -}
firstPass :: [ParsedValidCommand] -> ParseContext -> ParseContext
firstPass parsedValidCommands parseContext =
    let
        getCommand (ParsedValidCommand command) =
             command

        commands =
            map getCommand parsedValidCommands

    in
        foldlWithIndex (firstPassCombinator commands) parseContext (fromList commands)


firstPassCombinator :: [Command] -> ParseContext -> Int -> Command -> ParseContext
firstPassCombinator commands currentParseContext currentIndex command =
    let
        symbolTable =
            parseContextSymbolTable currentParseContext


        parseContextIncremented =
            let
                currentROMAddress =
                    parseContextCurrentROMAddress currentParseContext

                nextROMAddress =
                    currentROMAddress + 1

            in
                currentParseContext { parseContextCurrentROMAddress = nextROMAddress }

    in
        case command of
            PseudoCommand pseudoCommand ->
                let
                    hasPseudoCommandAlready =
                        SymbolTable.contains pseudoCommand symbolTable

                    maybeNextAddress =
                        getNextCommandAddress currentIndex commands

                in
                    if hasPseudoCommandAlready then
                        currentParseContext

                    else
                        let
                            maybeNextAddress =
                                getNextCommandAddress currentIndex commands

                        in
                            case maybeNextAddress of
                                Just nextAddress ->
                                    parseContextIncremented
                                        { parseContextSymbolTable =
                                            SymbolTable.addEntry pseudoCommand nextAddress symbolTable
                                        }

                                Nothing ->
                                    currentParseContext


            -- Increment other commands

            AInstruction _ ->
                parseContextIncremented

            CInstruction _ _ _ ->
                parseContextIncremented



getNextCommandAddress :: Int -> [Command] -> Maybe Int
getNextCommandAddress fromIndex commands =
    foldlWithIndex (getNextCommandAddressCombinator fromIndex) Nothing (fromList commands)


getNextCommandAddressCombinator :: Int -> Maybe Int -> Int -> Command -> Maybe Int
getNextCommandAddressCombinator fromIndex accumulator index command =
    case accumulator of
        Just _ ->
            -- We already have found it
            accumulator

        Nothing ->
            let
                isAfterGivenPosition =
                    index > fromIndex

                isNextCommand =
                    isAfterGivenPosition && (not $ isPseudoCommand command)

            in
                if isNextCommand then
                    Just index

                else
                    accumulator




-- SECOND PASS


{-| Second pass. Using symbol table with populated pseudo commands from first pass, go ahead and translate all the
encountered commands -}
secondPass :: [ParsedValidCommand] -> ParseContext -> ParseContext
secondPass parsedValidCommands parseContext =
    let
        getCommand (ParsedValidCommand command) =
             command

        commands =
            map getCommand parsedValidCommands

    in
        foldlWithIndex (secondPassCombinator commands) parseContext (fromList commands)


secondPassCombinator :: [Command] -> ParseContext -> Int -> Command -> ParseContext
secondPassCombinator commands currentParseContext currentIndex command =
    case command of
        AInstruction address ->
            let
                currentSymbolTable =
                    parseContextSymbolTable currentParseContext

                currentRAMAddress =
                    parseContextNextAvailableRAMAddress currentParseContext


                (exactAddress, newSymbolTable, newRAMAddress) =
                    case address of
                        ExactAddress ramAddress ->
                            (ramAddress, currentSymbolTable, currentRAMAddress)

                        AddressSymbol symbol ->
                            let
                                maybeRAMAddress =
                                    SymbolTable.getAddress symbol currentSymbolTable
                            in
                                case maybeRAMAddress of
                                    Just ramAddress ->
                                        (ramAddress, currentSymbolTable, currentRAMAddress)

                                    Nothing ->
                                        -- Symbol not found in table. Add new entry, incrementing RAM address
                                        let
                                            nextRAMAddress =
                                                currentRAMAddress + 1
                                        in
                                            (nextRAMAddress
                                            , SymbolTable.addEntry symbol nextRAMAddress currentSymbolTable
                                            , nextRAMAddress
                                            )

                instructionCode =
                    translateAInstruction exactAddress

            in
                currentParseContext
                { parseContextOutputInstructions = (parseContextOutputInstructions currentParseContext) ++ [instructionCode]
                , parseContextSymbolTable = newSymbolTable
                , parseContextNextAvailableRAMAddress = newRAMAddress
                }


        _ ->
            currentParseContext







parseLine :: (String, Int) -> ParsedLine
parseLine (line, lineNumber) =
    let
        cleanedLine =
            Cleaner.cleanLine line

        hasCommand =
            not (null cleanedLine)

        lineResult =
            if hasCommand then
                parseLineCommand cleanedLine

            else
                NoCommand

    in
        ParsedLine
        { parsedLineResult = lineResult
        , parsedLineNumber = lineNumber
        }



parseLineCommand :: String -> LineResult
parseLineCommand line
    | isLinePseudoCommand line = parsePseudoCommand line
    | isAInstruction line = parseAInstruction line
    | isCInstruction line = parseCInstruction line
    | otherwise = UnrecognisedCommand line



isLinePseudoCommand :: String -> Bool
isLinePseudoCommand line =
    line =~ "^\\(.+\\)$" :: Bool

isCInstruction :: String -> Bool
isCInstruction line =
    line =~ "^(0|D|A|M)?(;|=)?(.+)$" :: Bool

isAInstruction :: String -> Bool
isAInstruction line =
    line =~ "^@" :: Bool



parsePseudoCommand :: String -> LineResult
parsePseudoCommand line =
    let
        (_, _, firstParenRemoved) = line =~ "^\\(" :: (String, String, String)
        (symbol, _, _) = firstParenRemoved =~ "\\)$" :: (String, String, String)
    in
        ValidCommand $ PseudoCommand symbol


parseAInstruction :: String -> LineResult
parseAInstruction line =
    let
        (_, _, rawAddressString) =
            line =~ "^@" :: (String, String, String)

        maybeExactAddress =
            readMaybe rawAddressString :: Maybe Int

        address = case maybeExactAddress of
            Just exactAddress ->
                ExactAddress exactAddress

            Nothing ->
                AddressSymbol rawAddressString
    in
        ValidCommand $ AInstruction address


parseCInstruction :: String -> LineResult
parseCInstruction line =
    let
        maybeJump =
            getJump line

        maybeDestination =
            getDestination line

        maybeComputation =
            getComputation line
    in
        case maybeComputation of
            Just computation ->
                ValidCommand $ CInstruction computation maybeDestination maybeJump

            Nothing ->
                UnrecognisedCommand line



getComputation :: String -> Maybe Computation
getComputation line =
    let
        (_, _, matchWithEquals) =
            line =~ "=" :: (String, String, String)

        (_, _, matchWithSemicolon) =
            line =~ ";" :: (String, String, String)

        match =
            if not (null matchWithEquals) then
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
        (_, match, _) =
            line =~ "^(M|D|MD|A|AM|AD|AMD)=" :: (String, String, String)

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
        (_, match, _) =
            line =~ ";(JGT|JEQ|JGE|JLT|JNE|JLE|JMP)$" :: (String, String, String)
        
        jumpString =
            if not (null match) then
                tail match
            else
                ""
        
        hasJump =
            not (null jumpString)
    in
        if hasJump then
            Just (Jump jumpString)
        else
            Nothing
