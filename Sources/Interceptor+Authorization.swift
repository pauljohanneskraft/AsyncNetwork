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
    private let statusCodes: Set<Int>
    private let authenticate: (Bool, URLRequest) async throws -> String

    // MARK: Initialization

    public init(
        headerField: String,
        statusCodes: Set<Int>,
        authenticate: @escaping (Bool, URLRequest) async throws -> String
    ) {
        self.headerField = headerField
        self.statusCodes = statusCodes
        self.authenticate = authenticate
    }

    // MARK: Methods

    public func prepare(_ request: inout URLRequest) async throws {
        if request.value(forHTTPHeaderField: headerField) == nil {
            let value = try await authenticate(false, request)
            request.setValue(value, forHTTPHeaderField: headerField)
        }
    }

    public func prepareDownload(_ request: inout URLRequest) async throws {
        if request.value(forHTTPHeaderField: headerField) == nil {
            let value = try await authenticate(false, request)
            request.setValue(value, forHTTPHeaderField: headerField)
        }
    }

    public func prepareUpload(with request: inout URLRequest, from data: Data) async throws {
        if request.value(forHTTPHeaderField: headerField) == nil {
            let value = try await authenticate(false, request)
            request.setValue(value, forHTTPHeaderField: headerField)
        }
    }

    public func prepareUpload(with request: inout URLRequest, fromFile file: URL) async throws {
        if request.value(forHTTPHeaderField: headerField) == nil {
            let value = try await authenticate(false, request)
            request.setValue(value, forHTTPHeaderField: headerField)
        }
    }

    public func shouldRetry(_ request: URLRequest, for response: inout URLResponse, data: inout Data) async throws -> Bool {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              statusCodes.contains(statusCode) else {
            return false
        }
        return (try? await authenticate(true, request)) != nil
    }

    public func shouldRetryDownload(_ request: URLRequest, for response: inout URLResponse, destination: inout URL) async throws -> Bool {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              statusCodes.contains(statusCode) else {
            return false
        }
        return (try? await authenticate(true, request)) != nil
    }

    public func shouldRetryDownload(resumingFrom resumeData: Data, for response: inout URLResponse, destination: inout URL) async throws -> Bool {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              statusCodes.contains(statusCode) else {
            return false
        }
        throw URLError(.userAuthenticationRequired)
    }

    public func shouldRetryUpload(_ request: URLRequest, from sourceData: Data, for response: inout URLResponse, data: inout Data) async throws -> Bool {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              statusCodes.contains(statusCode) else {
            return false
        }
        return (try? await authenticate(true, request)) != nil
    }

    public func shouldRetryUpload(_ request: URLRequest, fromFile file: URL, for response: inout URLResponse, data: inout Data) async throws -> Bool {
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
              statusCodes.contains(statusCode) else {
            return false
        }
        return (try? await authenticate(true, request)) != nil
    }

}

extension Interceptor where Self == AuthorizationInterceptor {

    public static func authorization(
        headerField: String = "Authorization",
        statusCodes: Set<Int> = [401],
        authenticate: @escaping (Bool, URLRequest) async throws -> String
    ) -> Self {
        .init(
            headerField: headerField,
            statusCodes: statusCodes,
            authenticate: authenticate
        )
    }

}
