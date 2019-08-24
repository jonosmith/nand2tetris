//
//  Parser.swift
//  Assembler
//
//  Created by Jonathan Smith on 3/8/19.
//  Copyright © 2019 Jonathan Smith. All rights reserved.
//

import Foundation

/// The different command types
enum CommandType {
  /// An A command eg. `@i`, `@256`, `@R4`
  case ADDRESS
  
  /// C command eg. `D=D-M`
  case COMPUTE
  
  /// Pseudo command eg. `(LOOP)`
  case PSEUDO
}

/// Encapsulates access to the input code. Reads an assembly language command,
/// parses it, and provides convenient access to the commands
class Parser {
  
  private var lines = [Line]()
  
  // Keeps track of which line we are up to as we are processing
  private var currentIndex = 0
  
  /// The current Line we are up to
  var currentLine: Line {
    return lines[currentIndex]
  }
  
  init(from inputLines: [String]) {
    lines = inputLines.map({ Line($0) })
    
    // Set current line to first valid command (if there is one)
    if
      !currentLine.isValidCommand,
      let nextValidCommandIndex = nextValidCommandIndex()
    {
      currentIndex = nextValidCommandIndex
    }
  }
  
  /// The current assembly command the Parser is up to
  func currentCommand() -> String {
    return currentLine.cleanLine
  }
  
  // MARK: - Control
  
  /// Determines if there a more valid commands after the current line
  func hasMoreCommands() -> Bool {
    return nextValidCommandIndex() != nil
  }
  
  /// Step forward to the next valid command
  func advance() {
    guard hasMoreCommands() else {
      fatalError(
        "Tried to continue advancing but there are no more valid commands left"
      )
    }
    
    currentIndex = nextValidCommandIndex()!
    
  }

  private func nextValidCommandIndex() -> Int? {
    if currentIndex >= lines.count {
      return nil
    }
    
    let nextIndex = currentIndex + 1
    let remainingLines = lines[nextIndex...]
    
    let result = remainingLines.firstIndex(where: { $0.isValidCommand })
    
    return result
  }
  
  // Returns the type of the current command we are up to
  func commandType() -> CommandType? {
    return currentLine.commandType
  }
  
  
  // MARK: - Current command parts
  
  
  /// Returns the symbol or decimal Xxx of the current command @Xxx or (Xxx)
  /// Should be called only when commandType() is A_COMMAND or L_COMMAND
  func symbol() -> String {
    return currentLine.symbol()
  }
  
  /// Returns the destination mnemonic in the current C-command (8 possibilities).
  /// Should be called only when commandType() is C_COMMAND
  func dest() -> String {
    return currentLine.dest()
  }
  
  
  /// Returns the comp mnemonic in the current C-command (28 possibilities).
  /// Should only be called when commandType() is C_COMMAND
  func comp() -> String {
    return currentLine.comp()
  }
  
  
  /// Returns the jump mnemonic in the current C-command (8 possibilities).
  /// Should be called only when commantType() is C_COMMAND
  func jump() -> String {
    return currentLine.jump()
  }
  
}

/// Represents a single input line
struct Line {
  let rawLine: String
  
  var cleanLine: String {
    return rawLine
      |> stripWhitespace
      |> stripComments
  }
  
  var commandType: CommandType? {
    
    // eg. (LOOP), (OUTPUT_FIRST)
    let isPseudo = cleanLine.range(of: #"^\(.+\)$"#, options: .regularExpression) != nil
    
    // eg. @i, @256, @R4
    let isAddress = cleanLine.range(of: #"^\@.+$"#, options: .regularExpression) != nil
    
    // eg. M=M+1, D;JGT
    let isComputation = cleanLine.range(of: #".+(=|;).+"#, options: .regularExpression) != nil
    
    if isPseudo {
      return .PSEUDO
    } else if isAddress {
      return .ADDRESS
    } else if isComputation {
      return .COMPUTE
    }
    
    return nil
  }
  
  var isValidCommand: Bool {
    return commandType != nil
  }
  
  init(_ line: String) {
    rawLine = line
  }
  
  // MARK: - Command mnemonics
  
  /// The COMPUTATION mnemonic (if exists)
  func comp() -> String {
    guard commandType == .COMPUTE else {
      return ""
    }
    
    if let commandWithJumpMatch = cleanLine.range(
      of: #"(.+)(?=;)"#,
      options: .regularExpression
      ) {
      
      return String(cleanLine[commandWithJumpMatch])
      
    } else if let commandWithNoJump = cleanLine.range(
      of: #"(?<=(=)).+"#,
      options: .regularExpression
      ) {
      
      return String(cleanLine[commandWithNoJump])
      
    } else {
      return ""
    }
  }
  
  /// The JUMP mnemonic (if exists)
  func jump() -> String {
    guard commandType == .COMPUTE else {
      return ""
    }
    
    if let match = cleanLine.range(of: #"(?<=;)\w+"#, options: .regularExpression) {
      return String(cleanLine[match])
    } else {
      return ""
    }
  }
  
  /// The DESTINATION mnemonic (if exists)
  func dest() -> String {
    guard commandType == .COMPUTE else {
      return ""
    }
    
    if let match = cleanLine.range(of: #"\w+(?=\=)"#, options: .regularExpression) {
      return String(cleanLine[match])
    } else {
      return ""
    }
  }
  
  /// The SYMBOL mnemonic (if exists)
  func symbol() -> String {
    guard let commandType = commandType else {
      return ""
    }
    
    switch commandType {
    case .ADDRESS:
      return cleanLine.replacingOccurrences(of: #"@"#, with: "", options: .regularExpression)
      
    case .PSEUDO:
      let substringMatch = cleanLine.range(of: #"(?<=\().+(?=\))"#, options: .regularExpression)
      
      if let match = substringMatch {
        return String(cleanLine[match])
      } else {
        return cleanLine
      }
      
    default:
      return ""
    }
  }
  
  // MARK: - Helpers
  
  private func stripWhitespace(input: String) -> String {
    return input.replacingOccurrences(of: #"\s"#, with: "", options: .regularExpression)
  }
  
  private func stripComments(input: String) -> String {
    return input.replacingOccurrences(of: #"//.+"#, with: "", options: .regularExpression)
  }
  
}
