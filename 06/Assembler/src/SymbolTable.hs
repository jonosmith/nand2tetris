{-|
SymbolTable module. Data structure for holding all the symbols encountered when
parsing a hack file and their associated addresses
-}

module SymbolTable (
    SymbolTable

    -- Creation
    , makeNew

    -- Read/Write
    , addEntry
    , getAddress

    -- Helpers
    , contains
    , isMissing
) where


import Data.Map (Map)
import qualified Data.Map as Map



-- TYPES



newtype SymbolTable
    = SymbolTable (Map String Int)
    deriving (Show)



-- FUNCTIONS


{-| Creates a new empty symbol table -}
makeNew :: SymbolTable
makeNew =
    SymbolTable Map.empty



{-| Adds a symbol-address pair to the given symbol table -}
addEntry :: String -> Int -> SymbolTable -> SymbolTable
addEntry symbol address (SymbolTable symbolTableMap) =
    let
        newSymbolTableMap =
            Map.insert symbol address symbolTableMap

    in
        SymbolTable newSymbolTableMap



{-| Gets an address for the given symbol from the symbol table -}
getAddress :: String -> SymbolTable -> Maybe Int
getAddress symbol (SymbolTable symbolTableMap) =
    Map.lookup symbol symbolTableMap



{-| Checks if the symbol table has the given symbol -}
contains :: String -> SymbolTable -> Bool
contains symbol (SymbolTable symbolTableMap) =
    Map.member symbol symbolTableMap


{-| Checks if the symbol table is missing the given symbol (opposite of
contains)
-}
isMissing :: String -> SymbolTable -> Bool
isMissing symbol symbolTable =
    not $ contains symbol symbolTable
