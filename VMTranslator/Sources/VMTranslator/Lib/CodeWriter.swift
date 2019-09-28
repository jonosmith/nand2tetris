//
//  CodeWriter.swift
//  VMTranslator
//
//  Created by Jonathan Smith on 21/9/19.
//

import Foundation

enum CodeWriterError: Error {
  /// Any errors related to output (writing to disk)
  case outputError(message: String)
  
  /// Any errors with the actual conversion to assembly instructions
  case translationError(message: String)
}


class CodeWriter {
  
  let fileIO = FileIO()
  
  let outputDirectory: URL
  var currentFileName: String?
  
  var buffer = [String]()
  var customLabelCount = 0
  
  
  // MARK: - Setup
  
  
  init(outputDirectory: URL) {
    self.outputDirectory = outputDirectory
    
    initializeStackPointer()
  }
  
  /// Initializes the stack pointer to the required address eg. RAM[0] = 256
  private func initializeStackPointer() {
    aCommand(String(VM.RAMStackStart))
    cCommand(comp: "A", dest: "D")
    aCommand("SP")
    cCommand(comp: "D", dest: "M")
  }
  
  /**
      Sets a new filename
   
      - Note: Any subsequent writes will then occur in a new file
   */
  func setFileName(_ fileName: String) throws {
    currentFileName = fileName

    try prepareFileForWriting(fileName)
  }
  
  private func prepareFileForWriting(_ fileName: String) throws {
    let filePath = outputDirectory.appendingPathComponent(fileName).path

    do {
      
      try fileIO.writeOutput(text: "", filePath: filePath, mode: .overwrite)
      
    } catch FileIOError.standard(let fileIOErrorMessage) {
      
      throw CodeWriterError.outputError(message: fileIOErrorMessage)
    
    }
  }
  
  
  // MARK: - Main Interface
  
  private func flushBufferToFile() throws {
    guard let fileName = currentFileName else {
      throw CodeWriterError.outputError(message: "No filename specified to write to")
    }
    
    let filePath = outputDirectory.appendingPathComponent(fileName)
    
    do {
      // Write to file
      try fileIO.writeOutput(lines: buffer, filePath: filePath.path, mode: .append)
      
      // Clear buffer
      buffer.removeAll()
      
    } catch FileIOError.standard(let fileIOErrorMessage) {
      throw CodeWriterError.outputError(message: fileIOErrorMessage)
    }
  }
  
  /// Writes the assembly code that is the translation of the given arithmetic command
  func writeArithmetic(command: String) throws {
    switch command {
    case "add":
      binary("D+A")
    case "sub":
      binary("A-D")
    case "and":
      binary("D&A")
    case "or":
      binary("D|A")
    
    case "neg":
      unary("-D")
    case "not":
      unary("!D")
    
    case "eq":
      compare("JEQ")
    case "gt":
      compare("JGT")
    case "lt":
      compare("JLT")
      
    default:
      throw CodeWriterError.translationError(message: "Unrecognised arithmetic command '\(command)'")
    }
    
    try flushBufferToFile()
  }
  
  /// Writes the assembly code that is the translation of the given PUSH or POP command
  func writePushPop(commandType: CommandType, segment: String, index: Int) throws {
    switch commandType {
    case .PUSH:
      try writePush(segment: segment, index: index)
    
    case .POP:
      try writePop(segment: segment, index: index)

    default:
      throw CodeWriterError.translationError(message: "Invalid command type supplied to writePushPop()")
    }
  }
  
  
  /// Writes a PUSH command
  private func writePush(segment: String, index: Int) throws {
    if segment == "constant" {
      valueToStack(String(index))
      incrementSP()
    }
    
    try flushBufferToFile()
  }
  
  /// Writes a POP command
  private func writePop(segment: String, index: Int) throws {
    
  }
  
  // MARK: Arithmetic Functions

  private func unary(_ comp: String) {
    // Get Y
    decrementSP()
    stackTo("D")
    
    // Perform command
    cCommand(comp: comp, dest: "D")
    
    // Push back to stack
    compToStack("D")
    
    incrementSP()
  }
  
  private func binary(_ comp: String) {
    // Get Y
    decrementSP()
    stackTo("D")                        // A = SP
    
    // Get X
    decrementSP()
    stackTo("A")                        // A = SP
    
    // Do computation
    cCommand(comp: comp, dest: "D")           // D = comp
    
    // Push result to stack
    compToStack("D")
    
    incrementSP()
  }
  
  private func compare(_ jump: String) {
    let labelForResultTrue = createNewLabel("COMPARE_RESULT_TRUE")
    let labelForEnd = createNewLabel("COMPARE_END")
    
    // Get Y
    decrementSP()
    stackTo("D")                          // A = SP
    
    // Get X
    decrementSP()
    stackTo("A")                          // A = SP
    
    cCommand(comp: "D-A", dest: "D")      // D = D-A
    
    aCommand(labelForResultTrue)
    cCommand(comp: "D", jump: jump)       // D;jump
    
    // When result is false
    compToStack("0")
    
    // Shortcut to end
    aCommand(labelForEnd)                 // @COMPARE_RESULT_END
    cCommand(comp: "0", jump: "JMP")      // 0;JMP
    
    // When result is true
    labelCommand(labelForResultTrue)
    compToStack("1")
  
    // Finish
    labelCommand(labelForEnd)
    decrementSP()
  }
  
  // MARK: - Stack
  
  /// Push the result of the given computation to the stack
  private func compToStack(_ comp: String) {
    loadSP()                              // A = SP
    cCommand(comp: comp, dest: "M")       // M[SP] = comp
  }
  
  /// Push the given value to the top of the stack
  private func valueToStack(_ value: String) {
    aCommand(value)
    cCommand(comp: "A", dest: "D")
    compToStack("D")
  }
  
  /// Put the value in the top of the stack in the given destination
  private func stackTo(_ dest: String) {
    loadSP()
    cCommand(comp: "M", dest: dest)
  }

  
  /// Load the current stack pointer value into A
  private func loadSP() {
    aCommand("SP")
    cCommand(comp: "M", dest: "A")
  }
  
  
  private func incrementSP() {
    aCommand("SP")
    cCommand(comp: "M+1", dest: "M")
  }
  
  private func decrementSP() {
    aCommand("SP")
    cCommand(comp: "M-1", dest: "M")
  }

  
  // MARK: - Creating commands
  
  private func cCommand(comp: String, dest: String) {
    cCommand(comp: comp, dest: dest, jump: nil)
  }
  
  private func cCommand(comp: String, jump: String) {
    cCommand(comp: comp, dest: nil, jump: jump)
  }
  
  private func cCommand(comp: String, dest maybeDest: String?, jump maybeJump: String?) {
    var command = ""
    
    if let dest = maybeDest {
      command += dest + "="
    }
    
    command += comp
    
    if let jump = maybeJump {
      command += ";" + jump
    }
    
    buffer.append(command)
  }
  
  private func aCommand(_ address: String) {
    buffer.append("@" + address)
  }
  
  private func labelCommand(_ name: String) {
    buffer.append("(" + name + ")")
  }
  
  private func createNewLabel(_ name: String) -> String {
    customLabelCount += 1
    
    return name + "_" + String(customLabelCount)
  }
  
}
