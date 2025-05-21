//
//  JSONValue.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 21/05/2025.
//

import Foundation
enum JSONValue: Decodable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case object([String: JSONValue])
  case array([JSONValue])
  case null

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let b = try? container.decode(Bool.self) {
      self = .bool(b)
    } else if let i = try? container.decode(Int.self) {
      self = .number(Double(i))
    } else if let d = try? container.decode(Double.self) {
      self = .number(d)
    } else if let s = try? container.decode(String.self) {
      self = .string(s)
    } else if let arr = try? container.decode([JSONValue].self) {
      self = .array(arr)
    } else if let obj = try? container.decode([String: JSONValue].self) {
      self = .object(obj)
    } else {
      throw DecodingError.typeMismatch(
        JSONValue.self,
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Unsupported JSON type"
        )
      )
    }
  }
}
