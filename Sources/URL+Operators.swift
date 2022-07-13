//
//  URL+Operators.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 13.07.22.
//

import Foundation

infix operator /?: MultiplicationPrecedence

extension URL {

    public static func / (lhs: URL, rhs: String) -> URL {
        lhs.appendingPathComponent(rhs)
    }

    public static func /? (lhs: URL, rhs: [String: String]) -> URL! {
        lhs /? rhs.map { URLQueryItem(name: $0.key, value: $0.value) }
    }

    public static func /? (lhs: URL, rhs: [URLQueryItem]) -> URL! {
        guard var components = URLComponents(url: lhs, resolvingAgainstBaseURL: true) else {
            return nil
        }
        components.queryItems = rhs
        return components.url
    }

}
