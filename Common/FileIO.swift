//
//  FileIO.swift
//  Assembler
//
//  Created by Jonathan Smith on 11/8/19.
//

import Foundation


enum FileIOError: Error {
  case standard(String)
}


enum FileWriteMode {
  case append
  case overwrite
}


/// Manages reading and writing files
class FileIO {
  
  let fileManager = FileManager()
  
  // MARK: - Reading from file
  
  /// Read the given file into an array of strings representing each line
  func readInputFile(_ filePath: String) throws -> [String] {
    
    do {
      let contents = try String(contentsOfFile: filePath)

      return contents
        .replacingOccurrences(of: "\r\n", with: "\n")
        .split(separator: "\n").map({ String($0) })

    } catch {
      throw FileIOError.standard("Could not read the input file")
    }

  }
  
  // MARK: - Writing to file
  
  func writeOutput(lines: [String], filePath: String) throws {
    try writeOutput(lines: lines, filePath: filePath, mode: nil)
  }
  
  func writeOutput(lines: [String], filePath: String, mode: FileWriteMode?) throws {
    let text = lines.joined(separator: "\n")
    
    try writeOutput(text: text, filePath: filePath, mode: mode)
  }
  
  func writeOutput(text: String, filePath: String) throws {
    try writeOutput(text: text, filePath: filePath, mode: nil)
  }
  
  /// Writes the given text to a file
  func writeOutput(text: String, filePath: String, mode: FileWriteMode? = .overwrite) throws {    
    do {
      if fileManager.fileExists(atPath: filePath) && mode == .append {
        try writeToFileAppending(filePath: filePath, text: text)
        
      } else {
        try writeToFileOverwriting(filePath: filePath, text: text)
      }
      
    } catch let error as NSError {
      throw FileIOError.standard(
        """
        Encountered an error when trying to write the output:

        \(error)
        """
      )
    }
  }
  
  // MARK: - Helpers
  
  private func writeToFileAppending(filePath: String, text: String) throws {
    let fileUpdater = try FileHandle(forUpdating: URL(fileURLWithPath: filePath))
    fileUpdater.seekToEndOfFile()
    
    let textToWrite = text + "\n"
    
    fileUpdater.write(textToWrite.data(using: .utf8)!)
    
    fileUpdater.closeFile()
  }
  
  private func writeToFileOverwriting(filePath: String, text: String) throws {
    try text.write(toFile: filePath, atomically: false, encoding: String.Encoding.utf8)
  }
}
