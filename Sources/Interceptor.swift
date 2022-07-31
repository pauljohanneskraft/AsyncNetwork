//
//  Interceptor.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation

public protocol Interceptor {

    func prepare(_ request: inout URLRequest) async throws

    func prepareDownload(_ request: inout URLRequest) async throws
    func prepareDownload(resumingFrom resumeData: inout Data) async throws

    func prepareUpload(with request: inout URLRequest, from data: Data) async throws
    func prepareUpload(with request: inout URLRequest, fromFile file: URL) async throws

    func shouldRetry(_ request: URLRequest, for response: inout URLResponse, data: inout Data) async throws -> Bool

    func shouldRetryDownload(_ request: URLRequest, for response: inout URLResponse, destination: inout URL) async throws -> Bool
    func shouldRetryDownload(resumingFrom resumeData: Data, for response: inout URLResponse, destination: inout URL) async throws -> Bool

    func shouldRetryUpload(_ request: URLRequest, from sourceData: Data, for response: inout URLResponse, data: inout Data) async throws -> Bool
    func shouldRetryUpload(_ request: URLRequest, fromFile file: URL, for response: inout URLResponse, data: inout Data) async throws -> Bool

}

extension Interceptor {

    public func prepare(_ request: inout URLRequest) async throws {}

    public func prepareDownload(_ request: inout URLRequest) async throws {}
    public func prepareDownload(resumingFrom resumeData: inout Data) async throws {}

    public func prepareUpload(with request: inout URLRequest, from data: Data) async throws {}
    public func prepareUpload(with request: inout URLRequest, fromFile file: URL) async throws {}

    public func shouldRetry(_ request: URLRequest, for response: inout URLResponse, data: inout Data) async throws -> Bool { false }

    public func shouldRetryDownload(_ request: URLRequest, for response: inout URLResponse, destination: inout URL) async throws -> Bool { false }
    public func shouldRetryDownload(resumingFrom resumeData: Data, for response: inout URLResponse, destination: inout URL) async throws -> Bool { false }

    public func shouldRetryUpload(_ request: URLRequest, from sourceData: Data, for response: inout URLResponse, data: inout Data) async throws -> Bool { false }
    public func shouldRetryUpload(_ request: URLRequest, fromFile file: URL, for response: inout URLResponse, data: inout Data) async throws -> Bool { false }

}

