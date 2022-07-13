//
//  Interceptor+Preparation.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation

public struct PreparationInterceptor: Interceptor {

    // MARK: Stored Properties

    private let preparation: (inout URLRequest) async throws -> Void

    // MARK: Initialization

    public init(prepare preparation: @escaping (inout URLRequest) async throws -> Void) {
        self.preparation = preparation
    }

    // MARK: Methods

    public func prepare(_ request: inout URLRequest) async throws {
        try await preparation(&request)
    }

}

extension Interceptor where Self == PreparationInterceptor {

    public static func addHeaderFields(
        overrideExisting: Bool = false,
        _ headers: @escaping (URLRequest) -> [String: String]
    ) -> Self {
        .adaptHeaderFields { existingHeaders, request in
            existingHeaders.merge(headers(request)) { overrideExisting ? $1 : $0 }
        }
    }

    public static func adaptHeaderFields(
        _ modify: @escaping (inout [String: String], URLRequest) -> Void
    ) -> Self {
        .init { request in
            var headers = request.allHTTPHeaderFields ?? [:]
            modify(&headers, request)
            request.allHTTPHeaderFields = headers
        }
    }

}
