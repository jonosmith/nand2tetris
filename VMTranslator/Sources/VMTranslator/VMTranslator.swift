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
    
    // Initialize virtual RAM segments (SP, LCL etc.) if required
    if shouldInitializeVirtualRAMSegments {
      codeWriter.initializeVirtualRAMSegments()
    }
    
    for vmFile in vmFiles {
      translateFile(filePath: vmFile, codeWriter: codeWriter)
    }
  }
  
  private func translateFile(filePath: String, codeWriter: CodeWriter) {
    guard let inputLines = try? fileIO.readInputFile(filePath) else {
      return consoleIO.writeMessage("Could not read the file \(filePath)", to: .error)
    }
    
    let outputFilename = getOutputFilename(inputFilePath: URL(fileURLWithPath: filePath))
    
    do {
      try codeWriter.setFileName(outputFilename)
    } catch {
      return consoleIO.writeMessage(
        """
        Could not complete translation.
        
        Unexpected error trying to setup the file for output:
        
        \(error)
        """
      )
    }
    
    let parser = Parser(from: inputLines)
    
    while true {
      if let commandType = parser.commandType() {
        do {
          
          switch commandType {
          case .ARITHMETIC:
            try codeWriter.writeArithmetic(command: parser.currentCommand())

          case .PUSH, .POP:
            guard let arg1 = parser.arg1(), let arg2 = parser.arg2() else {
              handleInsufficientArguments(currentLine: parser.currentLine, expectedArguments: 2)
              break
            }
            
            try codeWriter.writePushPop(commandType: commandType, segment: arg1, index: arg2)
          
          default:
            consoleIO.writeMessage(
              """
              Command type not implemented yet:
              > \(parser.currentLine.cleaned)

              """
            )
          }

            
        } catch CodeWriterError.outputError(let outputErrorMessage) {
          handleCodeWriterOutputError(errorMessage: outputErrorMessage, currentLine: parser.currentLine)
          
        } catch CodeWriterError.translationError(let translationErrorMessage) {
          handleCodeWriterTranslationError(errorMessage: translationErrorMessage, currentLine: parser.currentLine)
        } catch {
          handleCodeWriterOtherErrors(currentLine: parser.currentLine)
        }
      }
      
      if parser.hasMoreCommands() {
        parser.advance()
      } else {
        break
      }
    }
    
    consoleIO.writeMessage("File translated: \(outputFilename)")
  }
}

// MARK: - Error handling
extension VMTranslator {
  
  private func handleInsufficientArguments(currentLine: Line, expectedArguments: Int) {
    let message =
      """
      Expected \(expectedArguments) for this line:
      
      > \(currentLine.original)
      
      """
    
    consoleIO.writeMessage(message, to: .error)
  }
  
  private func handleCodeWriterTranslationError(errorMessage: String, currentLine: Line) {
    let message =
      """
      
      
      Error: \(errorMessage)
      
      in
      
      \(printLine(currentLine))
      
      
      
      
      """
  
    consoleIO.writeMessage(message, to: .error)
  }
  
  private func handleCodeWriterOutputError(errorMessage: String, currentLine: Line) {
    let message =
      """
      Encountered an error trying to translate the line:
      
      \(printLine(currentLine))


      \(errorMessage)
      
      """
    
    consoleIO.writeMessage(message, to: .error)
  }
  
  private func handleCodeWriterOtherErrors(currentLine: Line) {
    let message =
      """
      Encountered an error trying to translate the line:
      \(printLine(currentLine))
      
      """
    
    consoleIO.writeMessage(message, to: .error)
  }
  
  private func printLine(_ line: Line) -> String {
    return "\(line.lineNumber) |    \(line.original)"
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
    
    return "\(inputFilename).asm"
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
      
      // Initialize virtual RAM segments (SP, LCL etc.) if required
      if shouldInitializeVirtualRAMSegments {
        codeWriter.initializeVirtualRAMSegments()
      }
      
      translateFile(filePath: inputFileOrDirectory, codeWriter: codeWriter)
    }
    
  }
}
