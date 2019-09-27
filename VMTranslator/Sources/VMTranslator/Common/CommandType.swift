//
//  CommandType.swift
//  VMTranslator
//
//  Created by Jonathan Smith on 17/9/19.
//

import Foundation

/**
  The different command types
*/
enum CommandType {
  case ARITHMETIC
  case PUSH
  case POP
  case LABEL
  case GOTO
  case IF
  case FUNCTION
  case RETURN
  case CALL
}
