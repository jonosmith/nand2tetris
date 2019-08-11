//
//  SymbolTable.swift
//  Assembler
//
//  Created by Jonathan Smith on 3/8/19.
//  Copyright © 2019 Jonathan Smith. All rights reserved.
//

import Foundation

/// Keeps a correspondence between symbolic labels and numeric addresses
struct SymbolTable {
  
  // Initialize symbols with some predefined ones
  private var symbols = [
    "SP": 0,
    "LCL": 1,
    "ARG": 2,
    "THIS": 3,
    "THAT": 4,
    "SCREEN": 16384,
    "KBD": 24576
  ]
  
  init() {
    // Initialize RAM symbols ie. R0, R1, R2 ... R15
    for i in Array(0...15) {
      symbols.updateValue(i, forKey: "R\(i)")
    }
  }
  
  mutating func addEntry(symbol: String, address: Int) {
    symbols.updateValue(address, forKey: symbol)
  }
  
  func contains(_ symbol: String) -> Bool {
    return symbols.contains(where: { (entry) -> Bool in
      let (key, _) = entry
      
      return key == symbol
    })
  }
  
  func getAddress(for symbol: String) -> Int? {
    return symbols[symbol]
  }
  
}
