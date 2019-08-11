//
//  Assembler.swift
//  Assembler
//
//  Created by Jonathan Smith on 10/8/19.
//  Copyright © 2019 Jonathan Smith. All rights reserved.
//

import Foundation


enum OptionType: String {
  case output = "o"
  case unknown
  
  init(value: String) {
    switch value {
    case "o": self = .output
    default: self = .unknown
    }
  }
}



/**
 Main program logic. Coordinates getting the input from various sources, parsing
 it and output final translates commands
 */
struct Assembler {
  
  /// Outputs extra data for debugging
  public var debug = false
  
  let consoleIO = ConsoleIO()
  
  
  // MARK: - Definitions
  
  private let ramAddressStart = 16
  
  
  
  // MARK: - Entry
  
  func staticMode() {
    let argCount = CommandLine.argc
    
    guard argCount > 1 else {
      consoleIO.writeMessage("Too few arguments", to: .error)
      consoleIO.printUsage()
      return
    }
    
    let inputFile = CommandLine.arguments[1]
    
    do {
      let result = try assembler.parse(file: inputFile)
    
      print(result.joined(separator: "\n"))
    } catch AssemblerError.standard(let message) {
      print("Error: \(message)")
    } catch {
      consoleIO.printUsage()
    }
  }
  
  func getOption(_ option: String) -> (option: OptionType, value: String) {
    return (OptionType(value: option), option)
  }
  
  
  
  /// Parse the given file
  func parse(file filePath: String) throws -> [String] {
    guard let inputLines = getInputLinesFromFile(filePath) else {
      throw AssemblerError.standard("Could not read the input file")
    }
    
    return parse(input: inputLines)
  }
  
  private func getInputLinesFromFile(_ filePath: String) -> [String]? {
    if let contents = try? String(contentsOfFile: filePath) {
      return contents.split(separator: "\r\n").map({ String($0) })
    }
    
    return nil
  }
  
  // MARK: - Main parsing
  private func parse(input inputLines: [String]) -> [String] {
    
    // 1. First pass - build up symbol table first with pseudo commands
    let symbolTable = firstPass(inputLines)
    
    
    // 2. Second pass. Translating and work out variables
    let outputList = secondPass(symbolTable: symbolTable, inputLines: inputLines)
    
    
    return transformForOutput(outputList)
  }
  
  private func firstPass(_ inputLines: [String]) -> SymbolTable {
    var parser = Parser(from: inputLines)
    var symbolTable = SymbolTable()
    
    var nextROMAddress = 0
    while true {
      // Check if this line is a valid command
      if let commandType = parser.commandType() {
        
        // Add pseudo command symbols to the symbol table
        if commandType == .PSEUDO {
          symbolTable.addEntry(symbol: parser.symbol(), address: nextROMAddress)
        } else {
          nextROMAddress += 1
        }
        
      }
      
      if parser.hasMoreCommands() {
        parser.advance()
      } else {
        break
      }
    }
    
    return symbolTable
  }
  
  private func secondPass(symbolTable symbolTableWithPseudoCommands: SymbolTable, inputLines: [String]) -> [Output] {
    var parser = Parser(from: inputLines)
    let code = Code()
    var output = [Output]()
    var symbolTable = symbolTableWithPseudoCommands
    
    // Keep track of free RAM addresses for variables encountered
    var nextFreeRAMAddress = self.ramAddressStart
    
    // Step through the input
    while true {
      if let commandType = parser.commandType() {
        if commandType == .ADDRESS {
          
          var ramAddress: Int?
          
          // Check if it is a raw address value
          if let addressValue = Int(parser.symbol()) {
            
            ramAddress = addressValue
            
          } else {
            
            // Address is a variable
            if let retrievedAddress = symbolTable.getAddress(for: parser.symbol()) {
              ramAddress = retrievedAddress
            } else {
              // We don't have this address yet. Assign it now
              ramAddress = nextFreeRAMAddress
              
              symbolTable.addEntry(symbol: parser.symbol(), address: nextFreeRAMAddress)
              
              nextFreeRAMAddress += 1
            }
            
          }
          
          if let address = ramAddress {
            
            let instruction = "0" + code.address(address)
            output.append(
              Output(
                originalLine: parser.currentLine.cleanLine,
                outputInstruction: instruction
              )
            )
            
          }
          
        } else if commandType == .COMPUTE {
          
          let instruction = "111"
            + code.comp(mnemonic: parser.comp())
            + code.dest(mnemonic: parser.dest())
            + code.jump(mnemonic: parser.jump())
          
          output.append(
            Output(
              originalLine: parser.currentLine.cleanLine,
              outputInstruction: instruction
            )
          )
          
        }
      }
      
      if parser.hasMoreCommands() {
        parser.advance()
      } else {
        break
      }
      
    }
    
    return output
  }
  
  private func transformForOutput(_ outputList: [Output]) -> [String] {
    return outputList.map({ (output) in
      if debug {
        return output.debugPrint
      } else {
        return output.outputInstruction
      }
    })
  }
  
}


private struct Output {
  let originalLine: String
  let outputInstruction: String
  
  var debugPrint: String {
    return "\(outputInstruction.rightPadding(toLength: 18, withPad: " ")) (\(originalLine))"
  }
}
