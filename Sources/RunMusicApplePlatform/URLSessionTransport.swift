import Foundation
import RunMusicCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct URLSessionHTTPTransport: HTTPTransport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        request.headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IntegrationTransportError.invalidResponse
        }
        let headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) { values, entry in
            values[String(describing: entry.key)] = String(describing: entry.value)
        }
        return HTTPResponse(statusCode: httpResponse.statusCode, headers: headers, body: data)
    }
}
