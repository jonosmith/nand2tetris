//
//  Parser.swift
//  VMTranslator
//
//  Created by Jonathan Smith on 24/8/19.
//

import Foundation

class Parser {
  
  private var lines = [Line]()
  
  // Keeps track of which line we are up to as we are processing
  private var currentIndex = 0
  
  /// The current Line we are up to
  var currentLine: Line {
    return lines[currentIndex]
  }
  
  init(from inputLines: [String]) {
    // Transform input
    lines = inputLines.enumerated().map({ (pair) -> Line in
      let (offset, element) = pair
      
      return Line(element, lineNumber: offset + 1)
    })
    
    // Set current line to first valid command (if there is one)
    if
      !currentLine.isValidCommand(),
      let nextValidCommandIndex = nextValidCommandIndex()
    {
      currentIndex = nextValidCommandIndex
    }
  }
  
  /// The current assembly command the Parser is up to
  func currentCommand() -> String {
    return currentLine.cleaned
  }
  
  
  // MARK: - Control
  
  
  /// Determines if there a more valid commands after the current line
  func hasMoreCommands() -> Bool {
    return nextValidCommandIndex() != nil
  }
  
  private func nextValidCommandIndex() -> Int? {
    if currentIndex >= lines.count {
      return nil
    }
    
    let nextIndex = currentIndex + 1
    let remainingLines = lines[nextIndex...]
    
    let result = remainingLines.firstIndex(where: { $0.isValidCommand() })
    
    return result
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
  

  // MARK: - Inspection
  
  
  func commandType() -> CommandType? {
    return currentLine.commandType()
  }
  
  /**
    The first argument of the current command.
   
    - Note: Only applicable for `ARITHMETIC` commands
  */
  func arg1() -> String? {
    let pieces = currentLine.cleaned.split(separator: " ")
    
    if pieces.count <= 1 {
      return nil
    }
    
    return String(pieces[1])
  }
  
  /**
    The second argument of the current command
   
   - Note: Only applicable for commands `PUSH`, `POP`, `FUNCTION`, `CALL`
  */
  func arg2() -> Int? {
    let pieces = currentLine.cleaned.split(separator: " ")
    
    if pieces.count <= 2 {
      return nil
    }
    
    return Int(pieces[2])
  }

}

