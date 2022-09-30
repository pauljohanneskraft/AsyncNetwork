//
//  Session.swift
//  AsyncNetwork
//
//  Created by Paul Kraft on 12.07.22.
//

import Foundation

public final class Session {

    // MARK: Stored Properties

    private let session: URLSession
    private let interceptors: [any Interceptor]
    private let maximumRetryCount: Int

    // MARK: Initialization

    public init(session: URLSession = .shared, interceptors: [any Interceptor] = [], maximumRetryCount: Int = 1) {
        self.session = session
        self.interceptors = interceptors
        self.maximumRetryCount = maximumRetryCount
    }

    // MARK: Methods - Data

    @discardableResult
    public func data(for request: URLRequest) async throws -> Data {
        try await _data(for: request, retryCount: maximumRetryCount)
    }

    @discardableResult
    public func data(from url: URL) async throws -> Data {
        try await data(for: .init(url: url))
    }

    // MARK: Helpers - Data

    private func _data(for request: URLRequest, retryCount: Int) async throws -> Data {
        var actualRequest = request

        try Task.checkCancellation()

        for interceptor in interceptors {
            try await interceptor.prepare(&actualRequest)
        }

        try Task.checkCancellation()

        var (data, response) = try await session.receiveData(for: actualRequest)

        try Task.checkCancellation()

        for interceptor in interceptors.reversed() {
            if try await interceptor.shouldRetry(actualRequest, for: &response, data: &data) && retryCount > 0 {
                try Task.checkCancellation()
                return try await _data(for: request, retryCount: retryCount - 1)
            }
        }

        try Task.checkCancellation()

        return data
    }

    // MARK: Methods - Download

    public func download(
        from url: URL,
		to destinationURL: URL? = nil,
        progress: @escaping (Double) -> Void = { _ in },
        resumeData resumeDataHandler: ((Data?) -> Void)? = nil
    ) async throws -> URL {

        try await download(
            for: .init(url: url),
			to: destinationURL,
            progress: progress,
            resumeData: resumeDataHandler
        )
    }

    public func download(
        for request: URLRequest,
		to destinationURL: URL? = nil,
        progress: @escaping (Double) -> Void = { _ in },
        resumeData resumeDataHandler: ((Data?) -> Void)? = nil
    ) async throws -> URL {

        try await _download(
            for: request,
			to: destinationURL,
            retryCount: maximumRetryCount,
            progress: progress,
            resumeData: resumeDataHandler
        )
    }

    public func download(
        resumeFrom resumeData: Data,
		to destinationURL: URL? = nil,
        progress: @escaping (Double) -> Void = { _ in },
        resumeData resumeDataHandler: ((Data?) -> Void)? = nil
    ) async throws -> URL {

        try await _download(
            resumeFrom: resumeData,
			to: destinationURL,
            retryCount: maximumRetryCount,
            progress: progress,
            resumeData: resumeDataHandler
        )
    }

    // MARK: Helpers - Download

    private func _download(
        for request: URLRequest,
		to destinationURL: URL?,
        retryCount: Int,
        progress: @escaping (Double) -> Void,
        resumeData resumeDataHandler: ((Data?) -> Void)?
    ) async throws -> URL {
        var actualRequest = request

        try Task.checkCancellation()

        for interceptor in interceptors {
            try await interceptor.prepareDownload(&actualRequest)
        }

        try Task.checkCancellation()

        var (url, response) = try await session.startDownload(
			for: actualRequest,
			to: destinationURL,
			progress: progress,
			resumeData: resumeDataHandler
		)

        try Task.checkCancellation()

        for interceptor in interceptors.reversed() {
            if try await interceptor.shouldRetryDownload(actualRequest, for: &response, destination: &url) && retryCount > 0 {
                try Task.checkCancellation()
				return try await _download(
					for: request,
					to: destinationURL,
					retryCount: retryCount - 1,
					progress: progress,
					resumeData: resumeDataHandler
				)
            }
        }

        try Task.checkCancellation()

        return url
    }

    private func _download(
        resumeFrom resumeData: Data,
		to destinationURL: URL?,
        retryCount: Int,
        progress: @escaping (Double) -> Void,
        resumeData resumeDataHandler: ((Data?) -> Void)?
    ) async throws -> URL {

        var actualResumeData = resumeData

        try Task.checkCancellation()

        for interceptor in interceptors {
            try await interceptor.prepareDownload(resumingFrom: &actualResumeData)
        }

        try Task.checkCancellation()

		var (url, response) = try await session.resumeDownload(
			from: actualResumeData,
			to: destinationURL,
			progress: progress,
			resumeData: resumeDataHandler
		)

        try Task.checkCancellation()

        for interceptor in interceptors.reversed() {
            if try await interceptor.shouldRetryDownload(resumingFrom: actualResumeData, for: &response, destination: &url) && retryCount > 0 {
                try Task.checkCancellation()

                return try await _download(
                    resumeFrom: resumeData,
					to: destinationURL,
                    retryCount: retryCount - 1,
                    progress: progress,
                    resumeData: resumeDataHandler
                )
            }
        }

        try Task.checkCancellation()

        return url
    }

    // MARK: Methods - Upload

    public func upload(
        with url: URL,
        from data: Data,
        progress: @escaping (Double) -> Void = { _ in }
    ) async throws -> Data {

        try await upload(
            with: .init(url: url),
            from: data,
            progress: progress
        )
    }

    public func upload(
        with request: URLRequest,
        from data: Data,
        progress: @escaping (Double) -> Void = { _ in }
    ) async throws -> Data {

        try await _upload(
            with: request,
            from: data,
            retryCount: maximumRetryCount,
            progress: progress
        )
    }

    public func upload(
        with url: URL,
        fromFile file: URL,
        progress: @escaping (Double) -> Void = { _ in }
    ) async throws -> Data {

        try await upload(
            with: .init(url: url),
            fromFile: file,
            progress: progress
        )
    }

    public func upload(
        with request: URLRequest,
        fromFile file: URL,
        progress: @escaping (Double) -> Void = { _ in }
    ) async throws -> Data {

        try await _upload(
            with: request,
            fromFile: file, retryCount: maximumRetryCount,
            progress: progress
        )
    }

    // MARK: Helpers - Upload

    private func _upload(
        with request: URLRequest,
        from data: Data,
        retryCount: Int,
        progress: @escaping (Double) -> Void
    ) async throws -> Data {

        var actualRequest = request

        try Task.checkCancellation()

        for interceptor in interceptors {
            try await interceptor.prepareUpload(with: &actualRequest, from: data)
        }

        try Task.checkCancellation()

        var (data, response) = try await session.startUpload(with: actualRequest, from: data)

        try Task.checkCancellation()

        for interceptor in interceptors.reversed() {
            if try await interceptor.shouldRetryUpload(actualRequest, from: data, for: &response, data: &data) && retryCount > 0 {
                try Task.checkCancellation()
                return try await _upload(with: request, from: data, retryCount: retryCount - 1, progress: progress)
            }
        }

        try Task.checkCancellation()

        return data
    }

    private func _upload(
        with request: URLRequest,
        fromFile file: URL,
        retryCount: Int,
        progress: @escaping (Double) -> Void
    ) async throws -> Data {

        var actualRequest = request

        try Task.checkCancellation()

        for interceptor in interceptors {
            try await interceptor.prepareUpload(with: &actualRequest, fromFile: file)
        }

        try Task.checkCancellation()

        var (data, response) = try await session.startUpload(with: actualRequest, fromFile: file, progress: progress)

        try Task.checkCancellation()

        for interceptor in interceptors.reversed() {
            if try await interceptor.shouldRetryUpload(actualRequest, fromFile: file, for: &response, data: &data) && retryCount > 0 {
                try Task.checkCancellation()
                return try await _upload(with: request, fromFile: file, retryCount: retryCount - 1, progress: progress)
            }
        }

        try Task.checkCancellation()

        return data
    }

}
