//
//  Interceptor+Validation.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation

public struct ValidationError: Error {

    // MARK: Stored Properties

    public let response: URLResponse
    public let data: Data

    // MARK: Initialization

    public init(response: URLResponse, data: Data) {
        self.response = response
        self.data = data
    }

}

public struct ValidationInterceptor: Interceptor {

    // MARK: Stored Properties

    let isValid: (URLResponse) -> Bool
    let makeError: (URLResponse, Data) -> any Error

    // MARK: Initialization

    public init(
        isValid: @escaping (URLResponse) -> Bool,
        makeError: @escaping (URLResponse, Data) -> any Error
    ) {
        self.isValid = isValid
        self.makeError = makeError
    }

    // MARK: Methods

    public func shouldRetry(_ request: URLRequest, for response: inout URLResponse, data: inout Data) async throws -> Bool {
        if !isValid(response) {
            throw makeError(response, data)
        }
        return false
    }

    public func shouldRetryDownload(_ request: URLRequest, for response: inout URLResponse, destination: inout URL) async throws -> Bool {
        if !isValid(response) {
            throw makeError(response, try Data(contentsOf: destination))
        }
        return false
    }

    public func shouldRetryDownload(resumingFrom resumeData: Data, for response: inout URLResponse, destination: inout URL) async throws -> Bool {
        if !isValid(response) {
            throw makeError(response, try Data(contentsOf: destination))
        }
        return false
    }

    public func shouldRetryUpload(_ request: URLRequest, from sourceData: Data, for response: inout URLResponse, data: inout Data) async throws -> Bool {
        if !isValid(response) {
            throw makeError(response, data)
        }
        return false
    }

    public func shouldRetryUpload(_ request: URLRequest, fromFile file: URL, for response: inout URLResponse, data: inout Data) async throws -> Bool {
        if !isValid(response) {
            throw makeError(response, data)
        }
        return false
    }

}

extension Interceptor where Self == ValidationInterceptor {

    public static func validate(
        isValid: @escaping (URLResponse) -> Bool,
        makeError: @escaping (URLResponse, Data) -> Error
    ) -> Self {
        .init(isValid: isValid, makeError: makeError)
    }

    public static func validateStatus(
        in validRange: Range<Int> = 200..<300,
        error: @escaping (URLResponse, Data) -> any Error = {
            ValidationError(response: $0, data: $1)
        }
    ) -> Self {
        .init { response in
            if let httpResponse = response as? HTTPURLResponse,
               !validRange.contains(httpResponse.statusCode) {
                return false
            }
            return true
        } makeError: {
            error($0, $1)
        }
    }

}
