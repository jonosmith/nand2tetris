//
//  main.swift
//  Assembler
//
//  Created by Jonathan Smith on 3/8/19.
//  Copyright © 2019 Jonathan Smith. All rights reserved.
//

import Foundation


let assembler = Assembler()
assembler.staticMode()





//
////
//// Parse input
////
//
//func invalidUsage() {
//  print("Usage: assembler file.asm [arguments]")
//}
//
//
//let arguments = CommandLine.arguments
//print(arguments)
//
//guard arguments.count == 2 else {
//  invalidUsage()
//  exit(0)
//}
//
//let inputFile = arguments[1]


//
// Run`
//

//var assembler = Assembler()
//assembler.debug = false
//
//do {
//  let result = try assembler.parse(file: inputFile)
//
//  print(result.joined(separator: "\n"))
//} catch AssemblerError.standard(let message) {
//  print("Error: \(message)")
//}
