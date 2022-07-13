//
//  Interceptor+Authorization.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation

public struct AuthorizationInterceptor: Interceptor {

    // MARK: Stored Properties

    private let headerField: String
    private let authenticate: (Bool, URLRequest) async throws -> String

    // MARK: Initialization

    public init(headerField: String, authenticate: @escaping (Bool, URLRequest) async throws -> String) {
        self.headerField = headerField
        self.authenticate = authenticate
    }

    // MARK: Methods

    public func prepare(_ request: inout URLRequest) async throws {
        if request.value(forHTTPHeaderField: headerField) == nil {
            let value = try await authenticate(false, request)
            request.setValue(value, forHTTPHeaderField: headerField)
        }
    }

    public func shouldRetry(_ request: URLRequest, for response: inout URLResponse, data: inout Data) async throws -> Bool {
        guard (response as? HTTPURLResponse)?.statusCode == 401 else {
            return false
        }
        return (try? await authenticate(true, request)) != nil
    }

}

extension Interceptor where Self == AuthorizationInterceptor {

    public static func authorization(
        headerField: String = "Authorization",
        authenticate: @escaping (Bool, URLRequest) async throws -> String
    ) -> Self {
        .init(headerField: headerField, authenticate: authenticate)
    }

}
