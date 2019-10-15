//
//  CodeWriter.swift
//  VMTranslator
//
//  Created by Jonathan Smith on 21/9/19.
//

import Foundation

enum CodeWriterError: Error {
  case translationError(String)
}

class CodeWriter {
  
  var debug = false
  
  let fileIO = FileIO()
  
  /**
    The output file to write to
   */
  private var outputFilePath: String?
  
  /**
    The file currently being translated
   */
  var currentFileName: String?
  
  var buffer = [String]()
  
  var customLabelCount = 0
  var lastFunctionEncountered: String?
  
  
  // MARK: - Output
  
  /**
    Set the current file being translated
   */
  func setFileName(_ fileName: String) {
    currentFileName = fileName
  }
  
  func setOutputFilePath(_ filePath: String) throws {
    outputFilePath = filePath
    
    try prepareFileForWriting(filePath: filePath)
  }
  
  private func prepareFileForWriting(filePath: String) throws {
    do {
      // Create blank file, erasing a previous one if it exists
      try fileIO.writeOutput(text: "", filePath: filePath, mode: .overwrite)
      
    } catch FileIOError.standard(let fileIOErrorMessage) {
      
      throw VMTranslatorError.outputError(errorMessage: fileIOErrorMessage)
    
    }
  }
  
  private func flushBufferToFile() throws {
    guard let filePath = outputFilePath else {
      throw VMTranslatorError.outputError(errorMessage: "No output file path specified to write to")
    }
    
    do {
      // Write to file
      try fileIO.writeOutput(lines: buffer, filePath: filePath, mode: .append)
      
      // Clear buffer
      buffer.removeAll()
      
    } catch FileIOError.standard(let fileIOErrorMessage) {
      throw VMTranslatorError.outputError(errorMessage: fileIOErrorMessage)
    }
  }
  
  
  // MARK: - Main Interface
  
  func writeInit() {
    if debug {
      comment("writeInit()")
    }
    
    // SP = 256
    aCommand("256")
    cCommand(comp: "A", dest: "D")
    registerToMemory("SP", register: "D")
    
    // Call init function
    call(functionName: "Sys.init", numArgs: 0)
  }
  
  /// Writes the assembly code that is the translation of the given arithmetic command
  func writeArithmetic(command: String) throws {
    if debug {
      comment("writeArithmetic: command=\(command)")
    }
    
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
      throw CodeWriterError.translationError("Unrecognised arithmetic command '\(command)'")
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
      fatalError("Invalid command type supplied to writePushPop()")
    }
  }
  
  
  /**
    Push values onto the stack from the given virtual memory segment
   
    - Parameter segment: The virtual memory segment to get the value from
    - Parameter index: The position in the virtual memory segment
   */
  private func writePush(segment: String, index: Int) throws {
    if debug {
      comment("writePush: segment=\(segment), index=\(String(index))")
    }
    
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
    
    case "static":
      staticToStack(index: index)
      
    default:
      throw CodeWriterError.translationError("Unrecognised PUSH segment \"" + segment + "\"")
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
    if debug {
      comment("writePop: segment=\(segment), index=\(String(index))")
    }
    
    switch segment {
    case "local", "argument", "this", "that":
      stackToMemory(segment: segment, index: index)
    
    case "temp":
      let address = VM.RAMTempSegmentStart + index
      stackToMemory(address: String(address))
    
    case "pointer":
      let address = VM.RAMPointerSegmentStart + index
      stackToMemory(address: String(address))
    
    case "static":
      stackToStatic(index: index)

    default:
      throw CodeWriterError.translationError("Unrecognised POP segment \"" + segment + "\"")
    }
    
    decrementSP()
    
    try flushBufferToFile()
  }
  
  func writeLabel(_ label: String) throws {
    if debug {
      comment("writeLabel: label=\(label)")
    }
    
    labelCommand(createFunctionScopedLabel(label))
    
    try flushBufferToFile()
  }
  
  func writeGoto(_ label: String) throws {
    if debug {
      comment("writeGoto: label=\(label)")
    }
    
    jump(to: createFunctionScopedLabel(label))
    
    try flushBufferToFile()
  }
  
  func writeIf(_ label: String) throws {
    if debug {
      comment("writeIf: label=\(label)")
    }
    
    // Pop last value off stack
    decrementSP()
    stackTo("D")
    
    // If != 0, goto given label
    aCommand(createFunctionScopedLabel(label))
    cCommand(comp: "D", jump: "JNE")
    
    try flushBufferToFile()
  }
  
  func writeFunction(functionName: String, numLocals: Int) throws {
    if numLocals < 0 {
      throw CodeWriterError.translationError("Number of local variables must be >= 0")
    }
    
    if debug {
      comment("writeFunction: functionName=\(functionName), numLocals=\(numLocals)")
    }
    
    // Record this new function
    lastFunctionEncountered = functionName
    
    // Create label for function entry
    labelCommand(functionName)
    
    // Allocate local variables
    if numLocals > 0 {
      for _ in 0..<numLocals {
        valueToStack(0)
        incrementSP()
      }
    }
    
    try flushBufferToFile()
  }
  
  func writeReturn() throws {
    if debug {
      comment("writeReturn")
    }
    
    let FRAMEAddr = VirtualRegister.VM1
    let RETURNAddr = VirtualRegister.VM2
    
    // FRAME = LCL
    memoryToRegister("D", address: "LCL")
    registerToMemory(FRAMEAddr, register: "D")
    
    // Get Return address
    aCommand("5")
    cCommand(comp: "D-A", dest: "A")
    cCommand(comp: "M", dest: "D")
    registerToMemory(RETURNAddr, register: "D")
    
    // Get return value for this function from the top of the stack and place in correct position for the caller
    decrementSP()
    stackTo("D")
    memoryToRegister("A", address: "ARG")
    cCommand(comp: "D", dest: "M")
    
    // Restore SP = ARG + 1
    memoryToRegister("A", address: "ARG")
    cCommand(comp: "A+1", dest: "D")
    registerToMemory("SP", register: "D")
    
    // Restore THAT = M[FRAME - 1]
    restoreFunctionSegment(segmentName: "THAT", FRAMEAddr: FRAMEAddr, offset: 1)
    
    // Restore THIS = M[FRAME - 2]
    restoreFunctionSegment(segmentName: "THIS", FRAMEAddr: FRAMEAddr, offset: 2)
    
    // Restore ARG = M[FRAME - 3]
    restoreFunctionSegment(segmentName: "ARG", FRAMEAddr: FRAMEAddr, offset: 3)
    
    // Restore LCL = M[FRAME - 4]
    restoreFunctionSegment(segmentName: "LCL", FRAMEAddr: FRAMEAddr, offset: 4)
    
    // Jump to the return address given by the caller
    memoryToRegister("A", address: String(RETURNAddr))
    jump()
    
    try flushBufferToFile()
  }
  
  private func restoreFunctionSegment(segmentName: String, FRAMEAddr: String, offset: Int) {
    memoryToRegister("D", address: FRAMEAddr)     // D = FRAME
    aCommand(String(offset))
    cCommand(comp: "D-A", dest: "A")              // A = FRAME - offset
    cCommand(comp: "M", dest: "D")                // D = M[FRAME - offset]
    registerToMemory(segmentName, register: "D")
  }
  
  /**
    Call a function after arguments have been pushed to the stack already
   */
  func writeCall(functionName: String, numArgs: Int) throws {
    call(functionName: functionName, numArgs: numArgs)
    
    try flushBufferToFile()
  }
  
  private func call(functionName: String, numArgs: Int) {
    if debug {
      comment("call: \(functionName), numArgs: \(numArgs)")
    }
    
    let returnAddress = createGloballyUniqueLabel(functionName + "_RETURN")
    
    // Add return address to stack
    valueToStack(returnAddress)
    incrementSP()
    
    // Add segment pointers to stack
    for address in ["LCL", "ARG", "THIS", "THAT"] {
      memoryToStack(address: address)
      incrementSP()
    }
    
    // Reposition ARG = SP - numArgs - 5
    let argOffset = numArgs + 5
    memoryToRegister("D", address: "SP")
    aCommand(String(argOffset))
    cCommand(comp: "D-A", dest: "D")
    registerToMemory("ARG", register: "D")
    
    // Reposition LCL: M[LCL] = M[SP]
    memoryToRegister("D", address: "SP")
    registerToMemory("LCL", register: "D")
    
    // Perform jump
    jump(to: functionName)
    
    // Write return address so program flow can return to execution here after running the called function
    labelCommand(returnAddress)
  }
  
  // MARK: - Arithmetic Functions

  private func unary(_ comp: String) {
    if debug {
      comment("unary: comp=\(comp)")
    }
    
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
    if debug {
      comment("binary: comp=\(comp)")
    }
    
    // Get Y
    decrementSP()
    stackTo("D")                            // A = SP
    
    // Get X
    decrementSP()
    stackTo("A")                            // A = SP
    
    // Do computation
    cCommand(comp: comp, dest: "D")         // D = comp
    
    // Push result to stack
    compToStack("D")
    
    incrementSP()
  }
  
  private func compare(_ jump: String) {
    if debug {
      comment("compare: jump=\(jump)")
    }
    
    let labelBase = createGloballyUniqueLabel("COMPARE")
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
    valueToStack(String(value))
  }
  
  private func valueToStack(_ value: String) {
    aCommand(value)
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
  
  /// Grab the value in memory at the given address and add to the current position in the stack
  private func memoryToStack(address: String) {
    // Get value from memory
    aCommand(address)
    cCommand(comp: "M", dest: "D")
    
    // Add value to top of stack
    compToStack("D")
  }
  
  private func staticToStack(index: Int) {
    guard let fileName = currentFileName else {
      fatalError("Current filename not set")
    }
    
    if debug {
      comment("staticToStack: index=\(String(index))")
    }
    
    // Assign the value of the variable to the D register
    aCommand(getStaticVariableName(fileName: fileName, index: index))
    cCommand(comp: "M", dest: "D")
    
    // Now push it to the stack
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
    
    if debug {
      comment("stackToMemory: segment=\(segment), index=\(String(index))")
    }
    
    // Get address of destination segment and store in a temp spot
    loadPointerForSegment(segmentPointerAddress: segmentPointerAddress, index: index)    // A = M[segment] + index
    cCommand(comp: "A", dest: "D")
    registerToMemory(VirtualRegister.VM1, register: "D")
    
    // Grab value from stack
    decrementSP()
    stackTo("D")
    incrementSP()
    
    // Get segment address again
    memoryToRegister("A", address: VirtualRegister.VM1)
    
    // Put stack value into segment at desired index
    cCommand(comp: "D", dest: "M")
  }
  
  private func stackToMemory(address: String) {
    if debug {
      comment("stackToMemory: address=\(address)")
    }
    
    // Grab value from stack
    decrementSP()
    stackTo("D")
    incrementSP()
    
    // Put stack value into given memory location
    aCommand(address)
    cCommand(comp: "D", dest: "M")
  }
  
  private func stackToStatic(index: Int) {
    guard let fileName = currentFileName else {
      fatalError("Current filename not set")
    }
    
    if debug {
      comment("stackToStatic: index=\(String(index))")
    }
    
    // Grab value from stack
    decrementSP()
    stackTo("D")
    incrementSP()
    
    // Assign it to the given variable's memory location
    aCommand(getStaticVariableName(fileName: fileName, index: index))
    cCommand(comp: "D", dest: "M")
  }
  
  // MARK: - Virtual Memory Segments

  /// Load the current stack pointer value into A
  private func loadSP() {
    memoryToRegister("A", address: "SP")
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

  private func memoryToRegister(_ register: String, address: String) {
    aCommand(address)
    cCommand(comp: "M", dest: register)
  }
  
  private func registerToMemory(_ address: String, register: String) {
    aCommand(address)
    cCommand(comp: register, dest: "M")
  }
  
  // MARK: - Core ASM Commands
  
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
  
  private func comment(_ comment: String) {
    buffer.append("// " + comment)
  }
  
  private func jump(to: String) {
    aCommand(to)
    jump()
  }
  
  private func jump() {
    cCommand(comp: "0", jump: "JMP")
  }
  
  // MARK: - Helpers
  
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
  
//  private func getOutputFilePathFrom(currentFileName fileName: String) -> String {
//    return outputDirectory.appendingPathComponent(fileName + "." + FileExtensions.output).path
//  }
  
  private func getStaticVariableName(fileName: String, index: Int) -> String {
    return fileName + "." + String(index)
  }
  
  /**
    Creates a globally unique label
   */
  private func createGloballyUniqueLabel(_ name: String) -> String {
    customLabelCount += 1
    
    return name + "_" + String(customLabelCount)
  }
  
  /**
    Try and create a function scoped label. Returns given label if we aren't
    currently in a function
   */
  private func createFunctionScopedLabel(_ label: String) -> String {
    if let currentFunction = lastFunctionEncountered {
      return currentFunction + "$" + label
    } else {
      return label
    }
  }
  
}
