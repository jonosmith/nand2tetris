//
//  VMConstants.swift
//  VMTranslator
//
//  Created by Jonathan Smith on 28/9/19.
//

import Foundation

enum VM {
  static let RAMStackStart = 256
  static let RAMLocalSegmentStart = 300
  static let RAMArgumentSegmentStart = 400
  static let RAMThisSegmentStart = 3000
  static let RAMThatSegmentStart = 3010
  static let RAMPointerSegmentStart = 3
  static let RAMTempSegmentStart = 5
}

enum VirtualRegister {
  // General purpose registers
  static let VM1 = "R13"
  static let VM2 = "R14"
  static let VM3 = "R15"
}
