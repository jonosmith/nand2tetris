//
//  VMTranslator.swift
//  VMTranslator
//
//  Created by Jonathan Smith on 21/9/19.
//

import Foundation


class VMTranslator {
  
  /// Outputs extra data for debugging
  public var debug = false
  
  /// For testing
  public var shouldInitializeVirtualRAMSegments = false
  
  public var arguments = [String]()
  
  
  private let consoleIO = ConsoleIO()
  private let fileIO = FileIO()
  private let fileManager = FileManager()
  
  
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
    if debug {
      codeWriter.debug = true
    }
    
    // Initialize virtual RAM segments (SP, LCL etc.) if required
    if shouldInitializeVirtualRAMSegments {
      codeWriter.initializeVirtualRAMSegments()
    }
    
    do {
      for vmFile in vmFiles {
        try translateFile(filePath: vmFile, codeWriter: codeWriter)
        
        consoleIO.writeMessage("File translated: \(vmFile)")
      }
    } catch {
      consoleIO.writeMessage(error.localizedDescription, to: .error)
    }
  }
  
  private func translateFile(filePath: String, codeWriter: CodeWriter) throws {
    guard let inputLines = try? fileIO.readInputFile(filePath) else {
      throw VMTranslatorError.inputError(file: filePath)
    }
    
    let inputFileURL = URL(fileURLWithPath: filePath)
    
    let outputFilename = getOutputFilename(inputFileURL: inputFileURL)
    
    try codeWriter.setFileName(outputFilename)
    
    let parser = Parser(from: inputLines)
    
    
    while true {
      try translateCommand(parser: parser, codeWriter: codeWriter, inputFileURL: inputFileURL)
      
      if parser.hasMoreCommands() {
        parser.advance()
      } else {
        break
      }
    }
  }
  
  private func translateCommand(parser: Parser, codeWriter: CodeWriter, inputFileURL: URL) throws {
    func handleInvalidArgs() -> VMTranslatorError {
      return VMTranslatorError.lineTranslationError(
        errorMessage: "Invalid arguments",
        line: parser.currentLine,
        fileName: inputFileURL.lastPathComponent
      )
    }
    
    if let commandType = parser.commandType() {
      do {
        
        switch commandType {
        case .ARITHMETIC:
          try codeWriter.writeArithmetic(command: parser.currentCommand())

        case .PUSH, .POP:
          guard let arg1 = parser.arg1(), let arg2 = parser.arg2() else {
            throw handleInvalidArgs()
          }
          
          try codeWriter.writePushPop(commandType: commandType, segment: arg1, index: arg2)
        
        case .LABEL:
          guard let arg1 = parser.arg1() else {
            throw handleInvalidArgs()
          }
          
          try codeWriter.writeLabel(arg1)
        
        case .GOTO:
          guard let arg1 = parser.arg1() else {
            throw handleInvalidArgs()
          }
          
          try codeWriter.writeGoto(arg1)
        
        case .IF:
          guard let arg1 = parser.arg1() else {
            throw handleInvalidArgs()
          }
          
          try codeWriter.writeIf(arg1)
        
        case .FUNCTION:
          guard let arg1 = parser.arg1(), let arg2 = parser.arg2() else {
            throw handleInvalidArgs()
          }
          
          try codeWriter.writeFunction(functionName: arg1, numLocals: arg2)
        
        case .RETURN:
          try codeWriter.writeReturn()
        
        default:
          throw VMTranslatorError.lineTranslationError(
            errorMessage: "Command type not implemented yet",
            line: parser.currentLine,
            fileName: inputFileURL.lastPathComponent
          )
        }
        
      } catch CodeWriterError.translationError(let message) {
        // Convert CodeWriter translation errors into an error with more context
        throw VMTranslatorError.lineTranslationError(
          errorMessage: message,
          line: parser.currentLine,
          fileName: inputFileURL.lastPathComponent
        )
      } catch {
        // Pass up to stop current file translation and output error
        throw error
      }
    }
  }
}


// MARK: - Helpers
extension VMTranslator {
  
  private func isValidVMFile(file: String) -> Bool {
    return NSURL(fileURLWithPath: file).pathExtension == "vm"
  }
  
  private func getOutputFilename(inputFileURL: URL) -> String {
    let inputFilenameAndExtension = inputFileURL.lastPathComponent
    
    let filenameMinusExtension = inputFilenameAndExtension.prefix(upTo: inputFilenameAndExtension.lastIndex { $0 == "." } ?? inputFilenameAndExtension.endIndex)
    
    return String(filenameMinusExtension)
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
      if debug {
        codeWriter.debug = true
      }
      
      // Initialize virtual RAM segments (SP, LCL etc.) if required
      if shouldInitializeVirtualRAMSegments {
        codeWriter.initializeVirtualRAMSegments()
      }
      
      do {
        try translateFile(filePath: inputFileOrDirectory, codeWriter: codeWriter)
      } catch {
        consoleIO.writeMessage(error.localizedDescription, to: .error)
      }
    }
    
  }
}
