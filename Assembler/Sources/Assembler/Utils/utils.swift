//
//  utils.swift
//  Assembler
//
//  Created by Jonathan Smith on 3/8/19.
//  Copyright © 2019 Jonathan Smith. All rights reserved.
//

import Foundation


//
// Forward pipe
//

precedencegroup ForwardPipe {
  associativity: left
  higherThan: LogicalConjunctionPrecedence
}

infix operator |> : ForwardPipe

public func |> <T, U>(value: T, function: ((T) -> U)) -> U {
  return function(value)
}



extension String {
  func leftPadding(toLength: Int, withPad character: Character) -> String {
    let stringLength = self.count
    
    if stringLength < toLength {
      return String(repeatElement(character, count: toLength - stringLength)) + self
    } else {
      return String(self.suffix(toLength))
    }
  }
  
  func rightPadding(toLength: Int, withPad character: Character) -> String {
    let stringLength = self.count
    
    if stringLength < toLength {
      return self + String(repeatElement(character, count: toLength - stringLength))
    } else {
      return String(self.prefix(toLength))
    }
  }
}
