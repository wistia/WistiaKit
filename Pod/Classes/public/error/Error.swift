//
//  Error.swift
//  Pods
//
//  Created by Jake Young on 6/14/16.
//

import Foundation

/// Debugging levels for WistiaKit
public enum DebuggingLevel {
    
    /// Shhh, fust be silent.
    case None
    
    /// Print the high level activity and errors.
    case Friendly
    
    /// Print all the things.
    case Annoying
}

internal func printErrorForDebuggingLevel(debuggingLevel debuggingLevel: DebuggingLevel, message: String? = nil, error: NSError? = nil) {
    
    switch debuggingLevel {
        
    case .None:
        break
    case .Friendly:
        
        // We print the message and fallthrough to allow .Annoying case to add to things.
        guard let message = message else { break }
        print(message)
        fallthrough
        
    case .Annoying:
        
        // We unrap the provided erorr and print the nerdy details.
        guard let error = error else { break }
        print("Error: \(error.description)), reason: \(error.localizedFailureReason)")
    }
    
}


/// The `Error` struct provides a convenience for creating custom WistiaKit NSErrors and Swift ErrorTypes.
public struct Error {
    
    /// The domain used for creating all Wistia errors.
    public static let Domain = "com.wistia.error"
    
}

protocol ErrorTypeWithDomain: ErrorType, CustomStringConvertible {
    
    /// The error domain for this item.
    static var Domain: String { get }
}

protocol ErrorProvider {
    associatedtype Error: ErrorTypeWithDomain
}

extension WistiaMedia: ErrorProvider {
    
    /// Errors specific to WistiaMedia objects.
    enum Error: ErrorTypeWithDomain {
        
        /// The hashed id provided doesnt pass validation rules. Its either not long enough, or completely invalid format wise.
        case HashedIdInvalid
        
        /// The hashed id passes validation rules, but is not found in your account. Was it deleted?
        case HashedIdNotFound
        
        var description: String {
            switch self {
            case .HashedIdInvalid: return "The hashed id provided for this Media is invalid."
            case .HashedIdNotFound: return "The hashed Id provided for this Media was not found in your account."
            }
        }
        
        /// The error domain for WistiaMedias.
        static var Domain: String {
            return Error.Domain
        }
    }
}

extension WistiaProject: ErrorProvider {
    
    /// Errors specific to WistiaMedia objects.
    enum Error: ErrorTypeWithDomain {
        
        /// The hashed id provided doesnt pass validation rules. Its either not long enough, or completely invalid format wise.
        case HashedIdInvalid
        
        /// The hashed id passes validation rules, but is not found in your account. Was it deleted?
        case HashedIdNotFound
        
        /// There are no medias for this project.
        case NoMediasForProject
        
        /// There are no medias for this project.
        case NoProjects
        
        var description: String {
            switch self {
            case .HashedIdInvalid: return "The hashed id provided for this project is invalid."
            case .HashedIdNotFound: return "The hashed Id provided for this project was not found in your account."
            case .NoMediasForProject: return "There are no medias for this project."
            case .NoProjects: return "There are no projects in your account."
            }
        }
        
        /// The error domain for WistiaProjects.
        static var Domain: String {
            return Error.Domain
        }
    }
}


extension WistiaAccount: ErrorProvider {
    
    /// Errors specific to WistiaMedia objects.
    enum Error: ErrorTypeWithDomain {
        
        /// The API Password provided for this account is invalid.
        case InvalidAPIPassword
        
        /// HLS is not currently enabled for this account. This will cause the `WistiaPlayerViewController` instance to fail to play any medias if `requireHLS' is set to true. If you need to enable HLS, please contact support@wistia.com.
        case HLSNotEnabledForAccount
        
        /// The API has a rate limit at 100 requests per minute. If there are more than 100 requests in a minute for a particular account, the service will respond with HTTP error 503 Service Unavailable and the Retry-After HTTP header will be set with a number of seconds to wait before trying again.
        case APIRateLimitExceeded
        
        var description: String {
            switch self {
            case .InvalidAPIPassword: return "The hashed id provided for this project is invalid."
            case .HLSNotEnabledForAccount: return "The hashed Id provided for this project was not found in your account."
            case .APIRateLimitExceeded: return "There are no medias for this project."
            }
        }
        
        /// The error domain for WistiaProjects.
        static var Domain: String {
            return Error.Domain
        }
    }
}