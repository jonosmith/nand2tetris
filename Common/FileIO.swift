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

/// Manages reading and writing files
class FileIO {
  
  func readInputFile(_ filePath: String) throws -> [String] {
    
    do {
      let contents = try String(contentsOfFile: filePath)

      return contents.split(separator: "\r\n").map({ String($0) })
    } catch {
      throw FileIOError.standard("Could not read the input file")
    }

  }
  
  func writeOutput(lines: [String], filePath: String) throws {
    do {
      try lines
        .joined(separator: "\n")
        .write(toFile: filePath, atomically: false, encoding: String.Encoding.utf8)
    } catch let error as NSError {
      throw FileIOError.standard("Encountered an error when trying to write the output \(error)")
    }
  }
  
}
