//
//  VMTranslator.swift
//  VMTranslator
//
//  Created by Jonathan Smith on 21/9/19.
//

import Foundation



enum VMTranslatorError: Error {
  case standard(String)
}



class VMTranslator {
  
  /// Outputs extra data for debugging
  public var debug = false
  
  public var arguments = [String]()
  
  
  private let consoleIO = ConsoleIO()
  private let fileIO = FileIO()
  private let fileManager = FileManager()
  
  
  // MARK: - Definitions
  let ramAddressStackStart = 256
  let ramAddressStackEnd = 2047
  

  // MARK: - Main Translation

  
  private func translateDirectory(path: String) {
    let maybeContents = try? fileManager.contentsOfDirectory(atPath: path)
    
    guard let contents = maybeContents else {
      return consoleIO.writeMessage("No files found in the given directory", to: .error)
    }
    
    let vmFiles = contents.filter { isValidVMFile(file: $0) }
    
    guard vmFiles.count > 0 else {
      return consoleIO.writeMessage("No valid VM files found in the given directory", to: .error)
    }
    
    let codeWriter = CodeWriter(outputDirectory: URL(fileURLWithPath: path))
    
    for vmFile in vmFiles {
      translateFile(filePath: vmFile, codeWriter: codeWriter)
    }
  }
  
  private func translateFile(filePath: String, codeWriter: CodeWriter) {
    guard let inputLines = try? fileIO.readInputFile(filePath) else {
      return consoleIO.writeMessage("Could not read the file \(filePath)", to: .error)
    }
    
    let outputFilename = getOutputFilename(inputFilePath: URL(fileURLWithPath: filePath))
    
    codeWriter.setFileName(outputFilename)
    
    let parser = Parser(from: inputLines)
    
    
    while true {
      if let commandType = parser.commandType() {
        do {
          
          if commandType == .ARITHMETIC {
            try codeWriter.writeArithmetic(command: parser.currentCommand())
          }
            
        } catch CodeWriterError.outputError(let outputErrorMessage) {
          handleCodeWriterOutputError(errorMessage: outputErrorMessage, currentLine: parser.currentLine.original)
          
        } catch CodeWriterError.translationError(let translationErrorMessage) {
          handleCodeWriterTranslationError(errorMessage: translationErrorMessage, currentLine: parser.currentLine.original)
        } catch {
          handleCodeWriterOtherErrors(currentLine: parser.currentLine.original)
        }
      }
      
      if parser.hasMoreCommands() {
        parser.advance()
      } else {
        break
      }
    }
    
  }
}

// MARK: - Error handling
extension VMTranslator {
  
  private func handleCodeWriterTranslationError(errorMessage: String, currentLine: String) {
    let message =
      """
      Encountered an error trying to translate the line:
      > \(currentLine)
      
      The error was:
      \(errorMessage)
      """
    
    consoleIO.writeMessage(message, to: .error)
  }
  
  private func handleCodeWriterOutputError(errorMessage: String, currentLine: String) {
    let message =
      """
      Encountered an error trying to translate the line:
      > \(currentLine)
      
      Specifically, this error was encountered trying to write to disk:
      \(errorMessage)
      """
    
    consoleIO.writeMessage(message, to: .error)
  }
  
  private func handleCodeWriterOtherErrors(currentLine: String) {
    let message =
      """
      Encountered an error trying to translate the line:
      > \(currentLine)
      """
    
    consoleIO.writeMessage(message, to: .error)
  }
}

// MARK: - Helpers
extension VMTranslator {
  
  private func isValidVMFile(file: String) -> Bool {
    return NSURL(fileURLWithPath: file).pathExtension == "vm"
  }
  
  private func getOutputFilename(inputFilePath: URL) -> String {
    let inputFilenameAndExtension = inputFilePath.lastPathComponent
    
    let filenameMinusExtension = inputFilenameAndExtension.prefix(upTo: inputFilenameAndExtension.lastIndex { $0 == "." } ?? inputFilenameAndExtension.endIndex)
    let inputFilename = String(filenameMinusExtension)
    
    return "\(inputFilename).hack"
  }
}

// MARK: - Available flows
extension VMTranslator {
  /// Main flow when given all arguments from command line invocation
  func staticMode() {
    let argCount = arguments.count
    
    guard argCount == 2 else {
      if argCount < 2 {
        consoleIO.writeMessage("Too few arguments", to: .error)
      } else {
        consoleIO.writeMessage("Too many arguments", to: .error)
      }
      
      consoleIO.printUsage()
      return
    }
    
    let inputFileOrDirectory = arguments[1]
    
    var isDirectory = ObjCBool(true)
    guard fileManager.fileExists(atPath: inputFileOrDirectory, isDirectory: &isDirectory) else {
      return consoleIO.writeMessage("Could not find the specified file/folder", to: .error)
    }
    
    if isDirectory.boolValue {
      
      translateDirectory(path: inputFileOrDirectory)
      
    } else {
      guard isValidVMFile(file: inputFileOrDirectory) else {
        return consoleIO.writeMessage("The given file is not a valid VM file", to: .error)
      }
      
      let directory = (URL(fileURLWithPath: inputFileOrDirectory)).deletingLastPathComponent()
      let codeWriter = CodeWriter(outputDirectory: directory)
      
      translateFile(filePath: inputFileOrDirectory, codeWriter: codeWriter)
    }
    
  }
}
