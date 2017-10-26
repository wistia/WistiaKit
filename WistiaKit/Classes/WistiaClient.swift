//
//  WistiaClient.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 10/17/17.
//

import Foundation

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

public class WistiaClient {

    fileprivate static let APIBase = URL(string: "https://api.wistia.com/v2/")
    //fileprivate static let APIUploadURL = "https://upload.wistia.com"

    public let token: String?
    public let session: URLSession

    open static var `default`: WistiaClient = {
        return WistiaClient()
    }()

    public init(token: String? = nil, sessionConfiguration: URLSessionConfiguration? = nil) {
        let config = sessionConfiguration ?? URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        self.token = token
    }

    public func get<T>(_ path: String, parameters: [String: String] = [:], completionHandler: @escaping ((T?, WistiaError?) ->())) where T: Codable {
        var params = parameters
        if token != nil {
            params["api_password"] = token
        }

        let get = getRequest(for: path, with: params)

        session.dataTask(with: get) { (data, urlResponse, error) in
            self.handleDataTaskResult(data: data, urlResponse: urlResponse, error: error, completionHandler: completionHandler)
            }.resume()
    }

    public func post<T>(_ path: String, parameters: [String: String] = [:], completionHandler: @escaping ((T?, WistiaError?) -> ())) where T: Codable {
//        var params = parameters
//        if token != nil {
//            params["api_password"] = token
//        }

        let post = postRequest(for: path, token: token, with: parameters)
        print("\(String(describing: post.httpMethod)): \(post) data is \(String(describing: String(data: post.httpBody!, encoding: .utf8)))")

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
            print("Received from API: \(String(describing: String(data: data, encoding: .utf8)))")
            let jsonDecoder = JSONDecoder()
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

    private func getRequest(for path: String, with parameters: [String: String]) -> URLRequest {
        var urlRequest = URLRequest(url: URL(string: path, relativeTo: WistiaClient.APIBase)!)
        var urlComponents = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)!

        //XXX: May need to URL encode (escape) these params
        let queryParams = parameters.map { "\($0)=\($1)" }.joined(separator: "&")
        urlComponents.percentEncodedQuery = queryParams
        urlRequest.url = urlComponents.url

        return urlRequest
    }

    private func postRequest(for path: String, token: String?, with parameters: [String: String]) -> URLRequest {
        var urlRequest = URLRequest(url: URL(string: path, relativeTo: WistiaClient.APIBase)!)
        //api_password still needs to be in the URL
        if let password = token {
            var urlComponents = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)!
            urlComponents.percentEncodedQuery = "api_password=\(password)"
            urlRequest.url = urlComponents.url
        }

        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

        //XXX: May need to URL encode (escape) these params
        let queryParams = parameters.map { "\($0)=\($1)" }.joined(separator: "&")
        urlRequest.httpBody = queryParams.data(using: .utf8, allowLossyConversion: false)

        return urlRequest
    }

}
