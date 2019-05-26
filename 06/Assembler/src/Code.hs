module Code (
    translateAInstruction,
    translateJumpCode,
    translateComputationCode,
    translateDestinationCode
) where

import Common.Command
import Utils (intToBinaryOfLength)



{-| Translates a given ram address into an A-instruction code
-}
translateAInstruction :: Int -> String
translateAInstruction ramAddress =
    "0" ++ intToBinaryOfLength 15 ramAddress



translateComputationCode :: Computation -> Maybe String
translateComputationCode (Computation computation) =
    let
        maybeA0BinaryString =
            case computation of
                "0" -> Just "101010"
                "1" -> Just "111111"
                "-1" -> Just "111010"
                "D" -> Just "001100"
                "A" -> Just "110000"
                "!D" -> Just "001101"
                "!A" -> Just "110001"
                "-D" -> Just "001111"
                "-A" -> Just "110011"
                "D+1" -> Just "011111"
                "A+1" -> Just "110111"
                "D-1" -> Just "001110"
                "A-1" -> Just "110010"
                "D+A" -> Just "000010"
                "D-A" -> Just "010011"
                "A-D" -> Just "000111"
                "D&A" -> Just "000000"
                "D|A" -> Just "010101"
                _ -> Nothing

        maybeA1BinaryString =
            case computation of
                "M" -> Just "110000"
                "!M" -> Just "110001"
                "-M" -> Just "110011"
                "M+1" -> Just "110111"
                "M-1" -> Just "110010"
                "D+M" -> Just "000010"
                "D-M" -> Just "010011"
                "M-D" -> Just "000111"
                "D&M" -> Just "000000"
                "D|M" -> Just "010101"
                _ -> Nothing


    in
        case maybeA0BinaryString of
            Just code ->
                Just ("0" ++ code)

            Nothing ->
                case maybeA1BinaryString of
                    Just code ->
                        Just ("1" ++ code)

                    Nothing ->
                        Nothing


translateDestinationCode :: Maybe Destination -> Maybe String
translateDestinationCode maybeDestination =
    case maybeDestination of
        Just (Destination destinationCode) ->
            case destinationCode of
                "M" -> Just "001"
                "D" -> Just "010"
                "MD" -> Just "011"
                "A" -> Just "100"
                "AM" -> Just "101"
                "AD" -> Just "110"
                "AMD" -> Just "111"
                _ -> Nothing

        Nothing ->
            Just "000"


translateJumpCode :: Maybe Jump -> Maybe String
translateJumpCode maybeJumpCommand =
    case maybeJumpCommand of
        Just (Jump jumpCommand) ->
            case jumpCommand of
                "JGT" -> Just "001"
                "JEQ" -> Just "010"
                "JGE" -> Just "011"
                "JLT" -> Just "100"
                "JNE" -> Just "101"
                "JLE" -> Just "110"
                "JMP" -> Just "111"
                _ -> Nothing

        Nothing ->
            Just "000"
