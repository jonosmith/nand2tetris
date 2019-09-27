//
//  Line.swift
//  VMTranslator
//
//  Created by Jonathan Smith on 17/9/19.
//

import Foundation

struct Line {

  /// The original line from the input file
  let original: String
  
  /// A cleaned version of the line ready for inspection
  var cleaned: String {
    return original
      |> stripWhitespace
      |> stripComments
  }
  
  // MARK: - Initialize
  
  init(_ line: String) {
    original = line
  }
  
  
  // MARK: - Parsing

  /// The command this line represents (if it is a valid command at all
  func commandType() -> CommandType? {
    let pieces = cleaned.split(separator: " ")
    
    if pieces.count == 0 {
      return nil
    }
    
    let commandString = pieces[0]
    
    switch commandString {
    case "add", "sub", "neg", "eq", "gt", "lt", "and", "or", "not":
      return .ARITHMETIC

    case "push":
      return .PUSH
    
    case "pop":
      return .POP
    
    case "label":
      return .LABEL
    
    case "goto", "if-goto":
      return .GOTO
      
    case "function":
      return .FUNCTION
    
    case "call":
      return .CALL
    
    case "return":
      return .RETURN
      
    default:
      return nil
    }
  }
  
  func isValidCommand() -> Bool {
    return commandType() != nil
  }
  
  // MARK: - Helpers
  
  private func stripWhitespace(input: String) -> String {
    return input.replacingOccurrences(of: #"\s"#, with: "", options: .regularExpression)
  }
  
  private func stripComments(input: String) -> String {
    return input.replacingOccurrences(of: #"//.+"#, with: "", options: .regularExpression)
  }
  
}
