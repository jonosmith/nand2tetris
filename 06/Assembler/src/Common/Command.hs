module Common.Command (
    Address(..),
    Destination(..),
    Computation(..),
    Jump(..),
    Command(..),
    isPseudoCommand
) where

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
    deriving (Show)



isPseudoCommand :: Command -> Bool
isPseudoCommand command =
    case command of
        PseudoCommand _ ->
            True

        _ ->
            False


