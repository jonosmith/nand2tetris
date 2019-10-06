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
  }
  
  /**
    Initializes the preset RAM segments. Used for testing
   */
  func initializeVirtualRAMSegments() {
    intializePointerValue(pointerName: "SP", value: VM.RAMStackStart)
    intializePointerValue(pointerName: "LCL", value: VM.RAMLocalSegmentStart)
    intializePointerValue(pointerName: "ARG", value: VM.RAMArgumentSegmentStart)
    intializePointerValue(pointerName: "THIS", value: VM.RAMThisSegmentStart)
    intializePointerValue(pointerName: "THAT", value: VM.RAMThatSegmentStart)
  }
  
  private func intializePointerValue(pointerName: String, value: Int) {
    aCommand(String(value))
    cCommand(comp: "A", dest: "D")
    aCommand(pointerName)
    cCommand(comp: "D", dest: "M")
  }
  
  /**
    Sets a new filename
   
    - Note: Any subsequent writes after setting a new filename will then occur
            in a new file
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
  
  
  /**
    Push values onto the stack from the given virtual memory segment
   
    - Parameter segment: The virtual memory segment to get the value from
    - Parameter index: The position in the virtual memory segment
   */
  private func writePush(segment: String, index: Int) throws {
    switch segment {
    case "constant":
      valueToStack(index)
    
    case "local", "argument", "this", "that":
      memoryToStack(segment: segment, index: index)
      
    case "temp":
      let address = VM.RAMTempSegmentStart + index
      memoryToStack(address: String(address))
    
    case "pointer":
      let address = VM.RAMPointerSegmentStart + index
      memoryToStack(address: String(address))
      
    default:
      throw CodeWriterError.translationError(message: "Unrecognised PUSH segment \"" + segment + "\"")
    }
    
    incrementSP()

    try flushBufferToFile()
  }
  
  /**
    Pop values off the stack and into the given virtual memory segment
 
    - Parameter segment: The virtual memory segment to put the value in
    - Parameter index: The position in the virtual memory segment
   */
  private func writePop(segment: String, index: Int) throws {
    switch segment {
    case "local", "argument", "this", "that":
      stackToMemory(segment: segment, index: index)
    
    case "temp":
      let address = VM.RAMTempSegmentStart + index
      stackToMemory(address: String(address))
    
    case "pointer":
      let address = VM.RAMPointerSegmentStart + index
      stackToMemory(address: String(address))

    default:
      throw CodeWriterError.translationError(message: "Unrecognised POP segment \"" + segment + "\"")
    }
    
    decrementSP()
    
    try flushBufferToFile()
  }
  
  // MARK: - Arithmetic Functions

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
    let labelBase = createNewLabel("COMPARE")
    let labelForResultTrue = labelBase + "_RESULT_TRUE"
    let labelForEnd = labelBase + "_COMPARE_END"
    
    // Get Y
    decrementSP()
    stackTo("D")
    
    // Get X
    decrementSP()
    stackTo("A")
    
    // eq: x = y
    // gt: x > y
    // lt: x < y
    cCommand(comp: "A-D", dest: "D")
    
    aCommand(labelForResultTrue)
    cCommand(comp: "D", jump: jump)
    
    // When result is false
    compToStack("0")
    
    // Shortcut to end
    aCommand(labelForEnd)
    cCommand(comp: "0", jump: "JMP")
    
    // When result is true
    labelCommand(labelForResultTrue)
    compToStack("-1")
  
    // Finish
    labelCommand(labelForEnd)
    incrementSP()
  }
    
  // MARK: - To Stack
  
  /// Push the result of the given computation to the stack
  private func compToStack(_ comp: String) {
    loadSP()                              // A = SP
    cCommand(comp: comp, dest: "M")       // M[SP] = comp
  }
  
  /// Push the given constant value to the top of the stack
  private func valueToStack(_ value: Int) {
    aCommand(String(value))
    cCommand(comp: "A", dest: "D")
    compToStack("D")
  }
  
  private func memoryToStack(segment: String, index: Int) {
    guard let segmentPointerAddress = getSegmentPointerAddress(segment) else {
      fatalError("Could not determine the address for given segment \"\(segment)\"")
    }
    
    // Get value from memory segment
    loadPointerForSegment(segmentPointerAddress: segmentPointerAddress, index: index)
    cCommand(comp: "M", dest: "D")
    
    // Add value to top of stack
    compToStack("D")
  }
  
  private func memoryToStack(address: String) {
    // Get value from memory
    aCommand(address)
    cCommand(comp: "M", dest: "D")
    
    // Add value to top of stack
    compToStack("D")
  }

  
  // MARK: From Stack
  
  /// Put the value in the top of the stack in the given destination
  private func stackTo(_ dest: String) {
    loadSP()
    
    cCommand(comp: "M", dest: dest)
  }
  
  /**
    Grab the value from the top of the stack and put it into the given segment
   */
  private func stackToMemory(segment: String, index: Int = 0) {
    guard let segmentPointerAddress = getSegmentPointerAddress(segment) else {
      fatalError("Could not determine the address for given segment \"\(segment)\"")
    }
    
    // Get address of destination segment and store in a temp spot
    loadPointerForSegment(segmentPointerAddress: segmentPointerAddress, index: index)    // A = M[segment] + index
    cCommand(comp: "A", dest: "D")
    aCommand(VirtualRegister.VM1)
    cCommand(comp: "D", dest: "M")
    
    // Grab value from stack
    decrementSP()
    stackTo("D")
    incrementSP()
    
    // Get segment address again
    aCommand(VirtualRegister.VM1)
    cCommand(comp: "M", dest: "A")
    
    // Put stack value into segment at desired index
    cCommand(comp: "D", dest: "M")
  }
  
  private func stackToMemory(address: String) {
    // Grab value from stack
    decrementSP()
    stackTo("D")
    incrementSP()
    
    // Put stack value into given memory location
    aCommand(address)
    cCommand(comp: "D", dest: "M")
  }
  
  // MARK: - Virtual Memory Segments

  /// Load the current stack pointer value into A
  private func loadSP() {
    aCommand("SP")
    cCommand(comp: "M", dest: "A")
  }
  
  private func loadPointerForSegment(segmentPointerAddress: String, index: Int) {
    aCommand(segmentPointerAddress)
    cCommand(comp: "M", dest: "D")
    
    if index > 0 {
      aCommand(String(index))
      cCommand(comp: "D+A", dest: "A")
    } else {
      cCommand(comp: "D", dest: "A")
    }
  }
  
  private func incrementSP() {
    aCommand("SP")
    cCommand(comp: "M+1", dest: "M")
  }
  
  private func decrementSP() {
    aCommand("SP")
    cCommand(comp: "M-1", dest: "M")
  }

  
  // MARK: - ASM Command creation
  
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
  
  
  // MARK: - Helpers
  
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
  
  /**
    Gets the address for the pointer to the given segment ie. local -> LCL
   */
  private func getSegmentPointerAddress(_ segment: String) -> String? {
    switch segment {
    case "local":
      return "LCL"
    
    case "argument":
      return "ARG"
    
    case "this":
      return "THIS"
    
    case "that":
      return "THAT"
      
    default:
      return nil
    }
  }
  
}
