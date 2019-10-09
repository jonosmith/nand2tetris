//
//  VMTranslatorError.swift
//  VMTranslator
//
//  Created by Jonathan Smith on 6/10/19.
//

import Foundation

enum VMTranslatorError: Error {
  case standard(String)
  
  /// Any errors related to reading an input file
  case inputError(file: String)
  
  /// Any errors related to output (writing to disk)
  case outputError(errorMessage: String)
  
  /// Encountered an error translating a specific VM instruction
  case lineTranslationError(errorMessage: String, line: Line, fileName: String)
}


extension VMTranslatorError: LocalizedError {
  var errorDescription: String? {
    switch self {
      
    case .standard(let genericMessage):
      return NSLocalizedString(genericMessage, comment: "")
    
    case .inputError(let file):
      let message =
        """
        
        Error reading the input file \(file)
        
        """
      
        return NSLocalizedString(message, comment: "")
      
    case .outputError(let errorMessage):
      let message =
        """
        
        Encountered an error trying to write to disk:
        
        \(errorMessage)
        
        """
      
      return NSLocalizedString(message, comment: "")
    
    case .lineTranslationError(let errorMessage, let line, let fileName):
      let message =
        """
        
        \(fileName): Error encountered translating this line:
        
        \(line.lineNumber) |    \(line.original)
        
        Error: \(errorMessage)
        
        
        """
      
      return NSLocalizedString(message, comment: "")
    }
  }
}
