//
//  Code.swift
//  Assembler
//
//  Created by Jonathan Smith on 3/8/19.
//  Copyright © 2019 Jonathan Smith. All rights reserved.
//


/// Translates Hack assembly language mnemonics into binary codes
class Code {
  
  private let destMappings = [
    "M": "001",
    "D": "010",
    "MD": "011",
    "A": "100",
    "AM": "101",
    "AD": "110",
    "AMD": "111"
  ]
  
  private let jumpMappings = [
    "JGT": "001",
    "JEQ": "010",
    "JGE": "011",
    "JLT": "100",
    "JNE": "101",
    "JLE": "110",
    "JMP": "111"
  ]
  
  let compMappings = [
    // when a = 0
    "0": "0101010",
    "1": "0111111",
    "-1": "0111010",
    "D": "0001100",
    "A": "0110000",
    "!D": "0001101",
    "!A": "0110001",
    "-D": "0001111",
    "-A": "0110011",
    "D+1": "0011111",
    "A+1": "0110111",
    "D-1": "0001110",
    "A-1": "0110010",
    "D+A": "0000010",
    "D-A": "0010011",
    "A-D": "0000111",
    "D&A": "0000000",
    "D|A": "0010101",
    
    // when a = 1
    "M": "1110000",
    "!M": "1110001",
    "-M": "1110011",
    "M+1": "1110111",
    "M-1": "1110010",
    "D+M": "1000010",
    "D-M": "1010011",
    "M-D": "1000111",
    "D&M": "1000000",
    "D|M": "1010101"
  ]
  
  func dest(mnemonic: String) -> String {
    if let code = destMappings[mnemonic] {
      return code
    } else {
      return "000"
    }
  }
  
  func comp(mnemonic: String) -> String {
    if let code = compMappings[mnemonic] {
      return code
    } else {
      return "0101010" // comp=0
    }
  }
  
  func jump(mnemonic: String) -> String {
    if let code = jumpMappings[mnemonic] {
      return code
    } else {
      return "000"
    }
  }
  
  func address(_ addr: Int) -> String {
    let binaryString = String(addr, radix: 2)
    
    return binaryString.leftPadding(toLength: 15, withPad: "0")
  }
}
