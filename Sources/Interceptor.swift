//
//  Interceptor.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation

public protocol Interceptor {

    func prepare(_ request: inout URLRequest) async throws

    func shouldRetry(_ request: URLRequest, for response: inout URLResponse, data: inout Data) async throws -> Bool

}

extension Interceptor {

    public func prepare(_ request: inout URLRequest) async throws {}

    public func shouldRetry(_ request: URLRequest, for response: inout URLResponse, data: inout Data) async throws -> Bool {
        false
    }

}
