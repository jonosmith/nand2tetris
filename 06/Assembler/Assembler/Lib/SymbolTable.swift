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
  
  private var symbols = [String: Int]()
  
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
