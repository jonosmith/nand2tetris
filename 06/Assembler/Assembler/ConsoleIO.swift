//
//  ConsoleIO.swift
//  Assembler
//
//  Created by Jonathan Smith on 11/8/19.
//  Copyright © 2019 Jonathan Smith. All rights reserved.
//

import Foundation


enum OutputType {
  case error
  case standard
}


class ConsoleIO {
  
  func writeMessage(_ message: String, to: OutputType = .standard) {
    switch to {
    case .standard:
      print("\u{001B}[;m\(message)")
      
    case .error:
      fputs("\u{001B}[0;31m\(message)\n", stderr)
    }
  }
  
  func printUsage() {
    let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent
    
    writeMessage("Usage:")
    writeMessage("\(executableName) file.asm -o file.hack")
    writeMessage("or")
    writeMessage("\(executableName) -h to show usage information")
  }
  
}
