//
//  StaticJWTAuthProvider.swift
//  T3ChatIOS
//
//  Created by Thomas Dye on 21/05/2025.
//

import Foundation
import ConvexMobile

struct StaticJWTAuthProvider: AuthProvider {
  public typealias AuthResult = String

  /// Your pre-fetched JWT
  private let jwt: String

  /// Initialize with the JWT you’ve obtained (e.g. from a previous login or server).
  public init(jwt: String) {
    self.jwt = jwt
  }

  /// “Logging in” just returns the stored JWT.
  public func login() async throws -> String {
    return jwt
  }

  /// “Logging out” here is a no-op — you could clear a cache or keychain if you like.
  public func logout() async throws {
    // e.g. Keychain.delete(jwtKey) if you’d stored it securely
  }

  /// Since we never pop up UI, just return the same JWT.
  public func loginFromCache() async throws -> String {
      return jwt
  }

  /// For a String result, the token is itself the ID token.
  public func extractIdToken(from authResult: String) -> String {
      return jwt
  }
}

extension StaticJWTAuthProvider {
  /// Decode the JWT and return the `"properties.id"` claim if present,
  /// otherwise fall back to the `"sub"` claim.
  func extractUserId(fromToken token: String) throws -> String {
    // 1) Split into header.payload.signature
    let segments = token.split(separator: ".")
    guard segments.count == 3 else {
      throw JWTError.malformedToken
    }

    // 2) Base64-decode the payload (segment[1])
    let payloadSegment = String(segments[1])
    // Pad to a multiple of 4
    let rem = payloadSegment.count % 4
    let padded = rem > 0
      ? payloadSegment + String(repeating: "=", count: 4 - rem)
      : payloadSegment

    guard let payloadData = Data(base64Encoded: padded,
                                 options: .ignoreUnknownCharacters) else {
      throw JWTError.invalidBase64
    }

    // 3) JSON-parse
    let obj = try JSONSerialization.jsonObject(with: payloadData, options: [])
    guard let payload = obj as? [String: Any] else {
      throw JWTError.unexpectedPayload
    }

    // 4) Extract properties.id or sub
    if let props = payload["properties"] as? [String: Any],
       let id = props["id"] as? String {
      return id
    }
    if let sub = payload["sub"] as? String {
      return sub
    }

    throw JWTError.claimNotFound
  }

  enum JWTError: Error {
    case malformedToken
    case invalidBase64
    case unexpectedPayload
    case claimNotFound
  }
}


