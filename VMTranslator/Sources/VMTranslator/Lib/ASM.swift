//
//  ASM.swift
//  VMTranslator
//
//  Created by Jonathan Smith on 21/9/19.
//

import Foundation


enum ASMCommandType {
  case ADDRESS
  case DATA
}


/// Represents a Hack assembly command
struct ASM {
  let commandType: ASMCommandType
  
}
