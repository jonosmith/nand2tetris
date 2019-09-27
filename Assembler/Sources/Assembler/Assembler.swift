//
//  Assembler.swift
//  Assembler
//
//  Created by Jonathan Smith on 10/8/19.
//  Copyright © 2019 Jonathan Smith. All rights reserved.
//

import Foundation


enum AssemblerError: Error {
  case standard(String)
}


/// Holds the original assembly command and output binary instruction
private struct MachineInstruction {
  /// Original assembly command
  let asm: String
  
  /// Translated instruction
  let hack: String
  
  /// A pretty print version for debugging
  var debugPrint: String {
    return "\(hack.rightPadding(toLength: 18, withPad: " ")) (\(asm))"
  }
}



/**
 Main program logic. Coordinates getting the input from various sources, parsing
 it and output final translates commands
 */
class Assembler {
  
  /// Outputs extra data for debugging
  public var debug = false
  
  private let consoleIO = ConsoleIO()
  private let fileIO = FileIO()
  
  
  // MARK: - Definitions
  
  private let ramAddressStart = 16
  
  
  // MARK: - Entry
  
  /// Main flow when given all arguments from command line invocation
  func staticMode() {
    let argCount = CommandLine.argc
    
    guard argCount >= 2 else {
      consoleIO.writeMessage("Too few arguments", to: .error)
      consoleIO.printUsage()
      return
    }
    
    guard argCount <= 3 else {
      consoleIO.writeMessage("Too many arguments", to: .error)
      consoleIO.printUsage()
      return
    }
    
    let inputFile = CommandLine.arguments[1]
    let maybeOutputFile = argCount == 3 ? CommandLine.arguments[2] : nil
    
    do {
      let inputLines = try fileIO.readInputFile(inputFile)
      let outputLines = assembler.parse(input: inputLines)
      
      // Output to file if given one
      if let outputFile = maybeOutputFile {
        try fileIO.writeOutput(lines: outputLines, filePath: outputFile)
        
        if debug {
          consoleIO.writeMessage(outputLines.joined(separator: "\n"))
        }

        consoleIO.writeMessage("Done")
      } else {
        // Otherwise output to stdout
        consoleIO.writeMessage(outputLines.joined(separator: "\n"))
      }
    } catch AssemblerError.standard(let message) {
      consoleIO.writeMessage("Error: \(message)", to: .error)
    } catch FileIOError.standard(let message) {
      consoleIO.writeMessage("File Error: \(message)", to: .error)
    } catch {
      consoleIO.printUsage()
    }
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
    let parser = Parser(from: inputLines)
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
  
  private func secondPass(
    symbolTable symbolTableWithPseudoCommands: SymbolTable,
    inputLines: [String]
    ) -> [MachineInstruction] {

    let parser = Parser(from: inputLines)
    let code = Code()
    var output = [MachineInstruction]()
    var symbolTable = symbolTableWithPseudoCommands
    
    // Keep track of free RAM addresses for variables encountered
    var nextFreeRAMAddress = self.ramAddressStart
    
    // Step through the input
    while true {
      if let commandType = parser.commandType() {
        if commandType == .ADDRESS {
          
          var ramAddress: Int?
          
          // Check if it is a raw address value eg. @256
          if let addressValue = Int(parser.symbol()) {
            
            ramAddress = addressValue
            
          } else {
            
            // Address is a variable eg. @i, @LOOP
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
              MachineInstruction(
                asm: parser.currentCommand(),
                hack: instruction
              )
            )
            
          }
          
        } else if commandType == .COMPUTE {
          
          let instruction = "111"
            + code.comp(mnemonic: parser.comp())
            + code.dest(mnemonic: parser.dest())
            + code.jump(mnemonic: parser.jump())
          
          output.append(
            MachineInstruction(
              asm: parser.currentCommand(),
              hack: instruction
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
  
  private func transformForOutput(_ outputList: [MachineInstruction]) -> [String] {
    return outputList.map({ (output) in
      if debug {
        return output.debugPrint
      } else {
        return output.hack
      }
    })
  }
  
}
