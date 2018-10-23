//
//  WistiaClient.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 10/17/17.
//

import Foundation
import AVFoundation

public enum WistiaError: Error {
    case unknown
    case other(Error?)
    case apiErrors([[String:String]])
    case decodingError(DecodingError)
    case badResponse(Data)
    case preconditionFailure(String)

    static func forApiErrors(errors: [[String:String]]?) -> WistiaError? {
        if let errors = errors {
            return WistiaError.apiErrors(errors)
        }
        else {
            return nil
        }
    }
}

//Every response has either a data or an error as the top level object
//They may have both in the case of a partial error (ie. request X,Y,Z but response only includes X and Y)
public struct WistiaResponse<DataType: Codable>: Codable {
    public let data: DataType?
    public let errors: [[String: String]]?
}

public protocol PersistenceManager {

    func downloadState(forMedia media: Media) -> Media.DownloadState

    /// returns an asset either fully downloaded or associated with a current download
    func asset(forMedia: Media) -> AVURLAsset?

    /// returns a fully downloaded asset
    func localAsset(forMedia media: Media) -> AVURLAsset?

    /// Idempotently ensures media is downloading
    /// Returns the result (ie. expect `.downloading`)
    func download(media: Media) -> Media.DownloadState

    /// Idempotently ensures `Media` is not downloading.
    /// Returns the result, which may be `.downloaded` if the download completed before being cancelled.
    func cancelDownload(media: Media) -> Media.DownloadState

    /// Idempotently ensures there is no local asset for the given `Media`
    /// Returns the result (ie. expect `.notDownloaded`)
    func removeDownload(forMedia media: Media) -> Media.DownloadState
}

public class WistiaClient {

    fileprivate static let APIBase = URL(string: "https://api.wistia.com/v2/")

    public let token: String?
    public let session: URLSession

    public let persistenceManager: PersistenceManager?

    /// Requests on `WistiaObject`s that require API access have an optional parameter
    /// where you may provide the `WistiaClient` used to complete the request.  If that
    /// parameter is left `nil`, the default client it used.
    /// It is configured without an access token, using a default URLSessionConfiguration,
    /// and without persistence.
    /// You can override this default client to provide your own configuration while
    /// keeping the syntactical conveninece and callsite simplicity of not passing it on every
    /// request that hits the API.
    public static var `default`: WistiaClient = {
        return WistiaClient()
    }()

    public init(token: String? = nil, sessionConfiguration: URLSessionConfiguration? = nil, persistenceManager: PersistenceManager? = nil) {
        let config = sessionConfiguration ?? URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        self.token = token
        self.persistenceManager = persistenceManager
    }

    public func get<T>(_ path: String, parameters: [String: String] = [:], completionHandler: @escaping ((T?, WistiaError?) ->())) where T: Codable {
        let get = getRequest(for: path, token: token, with: parameters)

        session.dataTask(with: get) { (data, urlResponse, error) in
            self.handleDataTaskResult(data: data, urlResponse: urlResponse, error: error, completionHandler: completionHandler)
            }.resume()
    }

    public func post<T>(_ path: String, parameters: [String: String] = [:], completionHandler: @escaping ((T?, WistiaError?) -> ())) where T: Codable {
        let post = postRequest(for: path, token: token, with: parameters)

        session.dataTask(with: post) { (data, urlResponse, error) in
            self.handleDataTaskResult(data: data, urlResponse: urlResponse, error: error, completionHandler: completionHandler)
        }.resume()
    }

    //public func put<T>
    //public func patch<T>
    //public func delete<T>
    //public func upload
}

//MARK: - Result Handling
extension WistiaClient {

    internal func handleDataTaskResult<T>(data: Data?, urlResponse: URLResponse?, error: Error?, completionHandler: @escaping ((T?, WistiaError?) ->())) where T: Codable {
        guard (data != nil || error != nil) else {
            //it could be argued that we should abort() here
            //we're not because we can reasonably recover & retry (network is expected to be lossy)
            completionHandler(nil, WistiaError.unknown)
            return
        }

        if let error = error {
            completionHandler(nil, WistiaError.other(error))
        }
        else if let data = data {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let decoded = try jsonDecoder.decode(WistiaResponse<T>.self, from: data)
                if decoded.data != nil || decoded.errors != nil {
                    completionHandler(decoded.data, WistiaError.forApiErrors(errors: decoded.errors))
                }
                else {
                    completionHandler(nil, WistiaError.badResponse(data))
                }
            } catch let error as DecodingError {
                completionHandler(nil, WistiaError.decodingError(error))
            } catch {
                completionHandler(nil, WistiaError.other(error))
            }
        }
    }

}

//MARK: - URL Building
extension WistiaClient {

    private func getRequest(for path: String, token: String?, with parameters: [String: String]) -> URLRequest {
        var urlRequest = URLRequest(url: URL(string: path, relativeTo: WistiaClient.APIBase)!)
        var urlComponents = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)!

        var queryParams = parameters.map { "\($0)=\($1)" }.joined(separator: "&")
        //api_password needs to be in the URL
        if let password = token {
            queryParams.append("&api_password=\(password)")
        }

        urlComponents.percentEncodedQuery = queryParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        urlRequest.url = urlComponents.url

        return urlRequest
    }

    private func postRequest(for path: String, token: String?, with parameters: [String: String]) -> URLRequest {
        var urlRequest = URLRequest(url: URL(string: path, relativeTo: WistiaClient.APIBase)!)
        //api_password needs to be in the URL
        if let password = token {
            var urlComponents = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)!
            urlComponents.percentEncodedQuery = "api_password=\(password)"
            urlRequest.url = urlComponents.url
        }

        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let queryParams = parameters.map { "\($0)=\($1)" }.joined(separator: "&")
        urlRequest.httpBody = queryParams.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.data(using: .utf8, allowLossyConversion: false)

        return urlRequest
    }

}
