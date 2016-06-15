//
//  WistiaAPI.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Alamofire

/**
 Create an instance of `WistiaAPI` to handle all of your interactions with the
 [Wistia Data API](http://wistia.com/doc/data-api).  Requests use the 
 `api_password`&nbsp;[authentication](http://wistia.com/doc/data-api#authentication) technique.  As such, you must
 initialize `WistiaAPI` with an appropriate API token.  If this token does not have permissions for
 the request your are making, they will fail and you will be notified in the completion handler.
 
 [Paging and sorting](http://wistia.com/doc/data-api#paging_and_sorting_responses) of requests is
 handled directly in the API, with default values matching the Data API already filled in.
 
 - Important: Paging is 1-indexed based on the `perPage` count.  If the returned object count equals the `perPage` size, you should make
 an additional request to determine if there are more objects.

 Some additional convenience methods are provided that do not map directly to a single Data API endpoint.
 These are provided as grease for common operations and called out appropriately.
 
 - NOTE: `WistiaAPI` is foundationally complete.  But it does not yet cover 100% of the [Wistia Data API](https://wistia.com/doc/data-api).
 If there is coverage you need, please submit an issue (or pull request!) at [WistiaKit on GitHub](https://github.com/wistia/WistiaKit).

 */
public class WistiaAPI {

    private static let APIBaseURL = "https://api.wistia.com/v1"

    private let apiToken: String

    //MARK: - Initialization

    /**
     Initialize the `WistiaAPI` with the access permissions as granted by the given `apiToken`.

     - Parameter apiToken: The API Token that will be used to access the [Wistia Data API](http://wistia.com/doc/data-api).
     */
        self.apiToken = apiToken
    }

    //MARK: - Sorting

    /**
     Enumeration of the attributes by which you may sort (for API methods that support sorting).
     
     - `Name`: Sort by name of the objects.
     - `MediaCount`: Sort the MediaCount property of the objects.
     - `Created`: Sort by the created date of the objects.
     - `Updated`: Sort by the updated date of the objects.
    */
    public enum SortBy: String {
        /// Sort by name of the objects.
        case Name = "name"

        /// Sort the MediaCount property of the objects.
        case MediaCount = "mediaCount"

        /// Sort by the created date of the objects.
        case Created = "created"

        /// Sort by the updated date of the objects.
        case Updated = "updated"
    }

    /**
     Choice of direction when sorting.
     
     - `Descending`: Sort with the largest value or most-recent date first. Values decreasing as you move forward in the list.
     - `Ascending`: Sort the the smallest value or oldest date first.  Values increasing as you move forward in the list.
     */
    public enum SortDirection: Int {
        /// Sort with the largest value or most-recent date first. Values decreasing as you move forward in the list.
        case Descending = 0

        /// Sort the the smallest value or oldest date first.  Values increasing as you move forward in the list.
        case Ascending = 1
    }

}

extension WistiaAPI {
    //MARK: - Account

    /**
     Get account information.  
     
     See [Wistia Data API - Account](http://wistia.com/doc/data-api#account)
     
     - Parameter completionHandler: The block to invoke when the API call completes.
         The block takes one argument: \
        `account` \
        The `WistiaAccount` object created from the API response.

    */
    public func showAccount(completionHander: (account: WistiaAccount?) -> () ){
        let params: [String : AnyObject] = ["api_password" : apiToken]

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/account.json", parameters: params)
            .responseJSON { response in

                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        
                        if let JSON = value as? [String: AnyObject],
                            account = ModelBuilder.accountFromHash(JSON) {
                            completionHander(account: account)
                        }
                    
                    case .Failure(let error):
                        
                        
                        completionHander(account: nil)
                }

            }
    }

}

//MARK: - Projects
extension WistiaAPI {

    /**
     List the projects in your accont.
     
     See [Wistia Data API - Projects: List](http://wistia.com/doc/data-api#projects_list).
     
     - Parameter page: The page of results to show.  Ex: `page` 2 with a `pageCount` of 10 will return results starting with the 11th object.
     - Parameter perPage: The number of results in a page.  This is the maximum number of results that may be returned in a single request.
     - Parameter sorting: A tuple specifying what attribute to sort by and the direction to sort in.
     - Parameter completionHandler: The block to invoke when the API call completes.
        The block takes one argument: \
        `projects` \
        An array of `WistiaProject` objects created from the API response.  May be empty.

     */
    public func listProjects(page page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)? = nil, completionHandler: (projects:[WistiaProject])->() ) {
        let params = WistiaAPI.addSorting(sorting, to: ["page" : page, "per_page" : perPage, "api_password" : apiToken])

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/projects.json", parameters: params)
            .responseJSON { response in
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        
                        if let JSON = value as? [[String: AnyObject]] {
                            
                            // We map each JSON to WistiaProject objects, and filter out any nil values
                            let projects = JSON.flatMap { ModelBuilder.projectFromHash($0) }
                            
                            // Hand over the array of parsed projects
                            completionHandler(projects: projects)
                            
                        }
                        
                    case .Failure(let error):
                        
                        
                        completionHandler(projects: [])
                    }
            }
    }

    /**
     Retrieve details about a specific project.
     
     The returned `WistiaProject` will also include an array of `WistiaMedia` objects.
     
     See [Wistia Data API - Projects: Show](http://wistia.com/doc/data-api#projects_show).

     - Parameter projectHashedID: The unique `hashed ID` of the project for which you want details.
     - Parameter completionHandler: The block to invoke when the API call completes.
        The block takes one argument: \
        `project` \
        The `WistiaProject` specified. `nil` if there was no match.

     */
    public func showProject(projectHashedID: String, completionHandler: (project: WistiaProject?)->() ) {
        let params:[String: AnyObject] = ["api_password" : apiToken]

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/projects/\(projectHashedID).json", parameters: params)
            .responseJSON { (response) in
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        
                        if let
                            JSON = value as? [String: AnyObject],
                            project = ModelBuilder.projectFromHash(JSON) {
                            completionHandler(project: project)
                        }
                    
                    case .Failure(let error):
                        completionHandler(project: nil)
                }
        }
    }

    // Create

    /**
     Create a new project in your Wistia account.
     
     Returns the newly created `WistiaProject`.
     
     See [Wistia Data API - Projects: Create](https://wistia.com/doc/data-api#projects_create)
     
     - Parameter name: The name of the project you want to create (required).
     - Parameter adminEmail: The email address of the person you want to set as the owner of this project. 
        Defaults to the Wistia Account Owner.
     - Parameter anonymousCanUpload: A flag indicating whether or not anonymous users may upload files to this 
        project.  Defaults to false.
     - Parameter anonymousCanDownload: A flag indicating whether or not anonymous users may download files from 
        this project.  Defaults to false.
     - Parameter public: A flag indicating whether or not the project is enabled for public access.  Defaults to
        false.
     - Parameter completionHandler: The block to invoke when the API call completes.
        The block takes one argument: \
        `project` \
        The newly created `WistiaProject` or nil if there was an error.

     */
    public func createProject(name: String, adminEmail: String?, anonymousCanUpload: Bool?, anonymousCanDownload: Bool?, isPublic: Bool?, completionHandler: (project: WistiaProject?)->() ) {
        var params:[String: AnyObject] = ["api_password" : apiToken]
        updateParamsWith(&params, name: name, adminEmail: adminEmail, anonymousCanUpload: anonymousCanUpload, anonymousCanDownload: anonymousCanDownload, isPublic: isPublic)


        Alamofire.request(.POST, "\(WistiaAPI.APIBaseURL)/projects.json", parameters: params)
            .responseJSON { (response) in
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        if let JSON = value as? [String: AnyObject],
                            project = ModelBuilder.projectFromHash(JSON) {
                            completionHandler(project: project)
                            
                        }
                    case .Failure(let error):
                        completionHandler(project: nil)
                }
            }
    }

    // Update

    /**
     Update an existing project in your Wistia account.

     The updated `WistiaProject` is returned.

     See [Wistia Data API - Projects: Update](https://wistia.com/doc/data-api#projects_update)

     - Parameter projectHashedID: The unique `hashed ID` of the project you want to update.
     - Parameter name: The project's new name.
     - Parameter anonymousCanUpload: A flag indicating whether or not anonymous users may upload files to this
        project.  Defaults to false.
     - Parameter anonymousCanDownload: A flag indicating whether or not anonymous users may download files from
        this project.  Defaults to false.
     - Parameter public: A flag indicating whether or not the project is enabled for public access.  Defaults to
        false.
     - Parameter completionHandler: The block to invoke when the API call completes.
        The block takes two arguments: \
        `success` \
        True if the project was updated. \
        `updatedProject` \
        The `WistiaProject` with updated attributes.
     */
    public func updateProject(projectHashedID: String, name: String?, anonymousCanUpload: Bool?, anonymousCanDownload: Bool?, isPublic: Bool?, completionHandler: (success: Bool, updatedProject: WistiaProject?)->() ) {
        var params:[String: AnyObject] = ["api_password" : apiToken]
        updateParamsWith(&params, name: name, adminEmail: nil, anonymousCanUpload: anonymousCanUpload, anonymousCanDownload: anonymousCanDownload, isPublic: isPublic)

        Alamofire.request(.PUT, "\(WistiaAPI.APIBaseURL)/projects/\(projectHashedID).json", parameters: params)
            .responseJSON(completionHandler: { (response) in
                
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                // Success! Let's parse that JSON.
                case .Success(let value):
                    
                    if let JSON = value as? [String: AnyObject],
                        project = ModelBuilder.projectFromHash(JSON) where response.response?.statusCode == 200 {
                        completionHandler(success: true, updatedProject: project)
                    }
                    
                case .Failure(let error):
                   completionHandler(success: true, updatedProject: nil)
                }
                
            })
    }

    // Delete

    /**
     Delete an existing project in your Wistia account.

     The returned `WistiaProject` no longer exists in your account.

     See [Wistia Data API - Projects: Delete](https://wistia.com/doc/data-api#projects_delete).

     - Parameter projectHashedID: The unique hashed ID of the project you want to delete.
     - Parameter completionHandler: The block to invoke when the API call completes.
        The block takes two arguments: \
        `success`\
        True if the project was deleted.
        `deletedProject` \
        The `WistiaProject` that was deleted. `nil` if there was no match.

     */
    public func deleteProject(projectHashedID: String, completionHandler: (success: Bool, deletedProject: WistiaProject?)->() ) {
        let params:[String: AnyObject] = ["api_password" : apiToken]

        Alamofire.request(.DELETE, "\(WistiaAPI.APIBaseURL)/projects/\(projectHashedID).json", parameters: params)
            .responseJSON(completionHandler: { (response) in
                
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                // Success! Let's parse that JSON.
                case .Success(let value):
                    
                    if let JSON = value as? [String: AnyObject],
                        project = ModelBuilder.projectFromHash(JSON) where response.response?.statusCode == 200 {
                        completionHandler(success: true, deletedProject: project)
                    }
                    
                case .Failure(let error):
                    completionHandler(success: true, deletedProject: nil)
                }
                
            })
    }

    // Copy

    /**
     Copy a project, including all media and sections.

     The returned `WistiaProject` represents the *new copy* of the project.

     See [Wistia Data API - Projects: Copy](https://wistia.com/doc/data-api#projects_copy).
     
     - Note: This method does not copy the projects sharing information (i.e. users that could see the old project 
        will not automatically be able to see the new one).

     - Parameter projectHashedID: The unique hashed ID of the project you want to copy.
     - Parameter adminEmail: The email address of the account Manager that will be the owner of the 
        new project. Defaults to the Account Owner if invalid or omitted.
     - Parameter completionHandler: The block to invoke when the API call completes.
        The block takes two arguments: \
        `success`\
        True if the project was copied. \
        `newProject` \
        The newly created `WistiaProject`; a copy of the project specified by hashed ID.  `nil` if unsuccessful.

     */
    public func copyProject(projectHashedID: String, adminEmail: String?, completionHandler: (success: Bool, newProject: WistiaProject?)->() ) {
        var params:[String: AnyObject] = ["api_password" : apiToken]
        updateParamsWith(&params, name: nil, adminEmail: adminEmail, anonymousCanUpload: nil, anonymousCanDownload: nil, isPublic: nil)

        Alamofire.request(.POST, "\(WistiaAPI.APIBaseURL)/projects/\(projectHashedID)/copy.json", parameters: params)
            .responseJSON(completionHandler: { (response) in
                
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        
                        if let JSON = value as? [String: AnyObject],
                            project = ModelBuilder.projectFromHash(JSON) where response.response?.statusCode == 201 {
                            completionHandler(success: true, newProject: project)
                        }
                        
                    // Failure, provide an empty result
                    case .Failure(let error):
                        completionHandler(success: true, newProject: nil)
                }
                
            })
    }


    //--- Helpers ---
    private func updateParamsWith(inout params: [String: AnyObject], name: String?, adminEmail: String?, anonymousCanUpload: Bool?, anonymousCanDownload: Bool?, isPublic: Bool?) {
        if let n = name {
            params["name"] = n
        }
        if let ae = adminEmail {
            params["adminEmail"] = ae
        }
        if let up = anonymousCanUpload {
            params["anonymousCanUpload"] = up ? "1" : "0"
        }
        if let down = anonymousCanDownload {
            params["anonymousCanDownload"] = down ? "1" : "0"
        }
        if let pub = isPublic {
            params["public"] = pub ? "1" : "0"
        }
    }
}

//MARK: - Medias
extension WistiaAPI {

    /**
     List the media in your account.  Request media with paging and sorting applied to the media attributes, but
     instead of returning an array of media, group the media into their respective projects.

     See [Wistia Data API - Medias: List](http://wistia.com/doc/data-api#medias_list).
     
     - Note: Convenience method.  See `listMedias(page:perPage:sorting:limitedToProject:completionHandler:)` 
     for the direct mirror of the Data API method.

     - Parameter page: The page of results to show.  Ex: `page` 2 with a `pageCount` of 10 will return results starting with the 11th object.
     - Parameter perPage: The number of results in a page.  This is the maximum number of results that may be returned in a single request.
     - Parameter sorting: A tuple specifying what attribute to sort by and the direction to sort in.
     - Parameter limitedToProject: Limit results to `WistiaMedia` within this `WistiaProject`
     - Parameter completionHandler: The block to invoke when the API call completes.
         The block takes one argument: \
         `projects` \
         An array of `WistiaProject` objects containing the returned `WistiaMedia` objects.  Will not contain empty projects.
         Projects returned will not have all of the normal project details.

     */
    public func listMediasGroupedByProject(page page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)? = nil, limitedToProject project: WistiaProject? = nil, completionHandler: (projects:[WistiaProject])->() ) {
        var params = WistiaAPI.addSorting(sorting, to: ["page" : page, "per_page" : perPage, "api_password" : apiToken])
        if let proj = project {
            params["project_id"] = proj.projectID
        }

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/medias.json", parameters: params)
            .responseJSON { response in

                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        
                        if let JSON = value as? [[String: AnyObject]] {
                            var projectsByHashedID = [String: WistiaProject]()
                            
                            for mediaHash in JSON {
                                //1) Make Media
                                if let media = ModelBuilder.mediaFromHash(mediaHash) {
                                    
                                    //2) Find project it's in (or create it anew)
                                    if let projectHash = mediaHash["project"] as? [String: AnyObject], var project = ModelBuilder.projectFromHash(projectHash) {
                                        if projectsByHashedID.indexForKey(project.hashedID) == nil {
                                            project.medias = [WistiaMedia]()
                                            projectsByHashedID[project.hashedID] = project
                                        }
                                        //3) add media to project it's in
                                        projectsByHashedID[project.hashedID]!.medias!.append(media)
                                    }
                                }
                                
                            }
                            completionHandler(projects: Array(projectsByHashedID.values))
                            
                        }
                    
                    // Failure, provide an empty result
                    case .Failure(let error):
                        completionHandler(projects: [])
                }
        }
    }

    /**
     List the media in your account.  Supports paging and [filtering](https://wistia.com/doc/data-api#filtering).
     
     See [Wistia Data API - Medias: List](http://wistia.com/doc/data-api#medias_list).

     - Parameter page: The page of results to show.  Ex: `page` 2 with a `pageCount` of 10 will return results starting with the 11th object.
     - Parameter perPage: The number of results in a page.  This is the maximum number of results that may be returned in a single request.
     - Parameter sorting: A tuple specifying what attribute to sort by and the direction to sort in.
     - Parameter filterByProject: Limit results to `WistiaMedia` within this `WistiaProject`
     - Parameter filterByName: Find a media or medias whose name exactly matches this parameter.
     - Parameter filterByType: A string specifying which type of media you would like to get. Values can be Video, Audio, Image,
        PdfDocument, MicrosoftOfficeDocument, Swf, or UnknownType.
     - Parameter filterByHashedID: Find the media by `hashedID`
     - Parameter completionHandler: The block to invoke when the API call completes.
         The block takes one argument: \
         `medias` \
         An array of `WistiaMedia` objects returned by the API call.  Will be empty when request page starts beyond the last item.

     */
    public func listMedias(page page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)? = nil, filterByProject project: WistiaProject? = nil, filterByName name: String? = nil, filterByType type: String? = nil, filterByHashedID hashedID: String? = nil, completionHandler: (medias:[WistiaMedia])->() ) {
        var params = WistiaAPI.addSorting(sorting, to: ["page" : page, "per_page" : perPage, "api_password" : apiToken])
        if let proj = project {
            params["project_id"] = proj.projectID
        }
        if let n = name {
            params["name"] = n
        }
        if let t = type {
            params["type"] = t
        }
        if let hid = hashedID {
            params["hashed_id"] = hid
        }

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/medias.json", parameters: params)
            .responseJSON { response in

                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        
                        if let JSON = value as? [[String: AnyObject]] {
                            
                            // Map JSON and toss out nil values
                            let medias = JSON.flatMap { ModelBuilder.mediaFromHash($0) }
                            completionHandler(medias: medias)
                            
                        }
                        
                    // Failure, provide an empty result
                    case .Failure(let error):
                        completionHandler(medias: [])
                }
                
        }
    }

    /**
     Retrieve details about a specific media.


     See [Wistia Data API - Medias: Show](http://wistia.com/doc/data-api#medias_show).

     - Parameter mediaHashedID: The unique `hashed ID` of the media for which you want details.
     - Parameter completionHandler: The block to invoke when the API call completes.
         The block takes one argument: \
         `media` \
         The `WistiaMedia` specified. `nil` if there was no match.

     */
    public func showMedia(mediaHashedID: String, completionHandler: (media: WistiaMedia?)->() ) {
        let params:[String: AnyObject] = ["api_password" : apiToken]

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID).json", parameters: params)
            .responseJSON { (response) in
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        if let
                            JSON = value as? [String: AnyObject],
                            media = ModelBuilder.mediaFromHash(JSON) {
                            completionHandler(media: media)
                        }
                    // Failure, provide an empty result
                    case .Failure(let error):
                        completionHandler(media: nil)
                }
        }
    }

    // Update
    /**
     Update attributes on a piece of media.
     
     See [Wistia Data API - Medias: Update](http://wistia.com/doc/data-api#medias_update).
     
     - Parameter mediaHashedID: The unique `hashedID` of the media you want to update.
     - Parameter name: The media's new name.
     - Parameter newStillMediaId: The `hashedID` of an image that will replace the still that's displayed before the player starts playing. Media to update must be a video and new still must reference an image, or the call will fail.
     - Parameter description: A new description for this media. Accepts plain text or markdown.
     - Parameter completionHandler: The block to invoke when the API call completes.
        The block takes two arguments: \
        `success` \
        True if the media was updated. \
        `updatedMedia` \
        The `WistiaMedia` with updated attributes.
     */
    public func updateMedia(mediaHashedID: String, name: String?, newStillMediaId: String?, description: String?, completionHandler: (success: Bool, updatedMedia: WistiaMedia?)->() ) {
        var params:[String: AnyObject] = ["api_password" : apiToken]
        if let n = name {
            params["name"] = n
        }
        if let nsmi = newStillMediaId {
            params["new_still_media_id"] = nsmi
        }
        if let d = description {
            params["description"] = d
        }

        Alamofire.request(.PUT, "\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID).json", parameters: params)
            .responseJSON(completionHandler: { (response) in
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                // Success! Let's parse that JSON.
                case .Success(let value):
                    
                    if let
                        JSON = value as? [String: AnyObject],
                        media = ModelBuilder.mediaFromHash(JSON) where response.response?.statusCode == 200 {
                        completionHandler(success: true, updatedMedia: media)
                    }
                    
                // Failure, provide an empty result
                case .Failure(let error):
                    completionHandler(success: true, updatedMedia: nil)
                }
                
                
            })
    }

    // Delete

    /**
     Delete an existing media in your Wistia account.

     The returned `WistiaMedia` no longer exists in your account.

     See [Wistia Data API - Medias: Delete](https://wistia.com/doc/data-api#medias_delete).

     - Parameter mediaHashedID: The unique hashed ID of the media you want to delete.
     - Parameter completionHandler: The block to invoke when the API call completes.
        The block takes two arguments: \
        `success`\
        True if the media was deleted.
        `deletedMedia` \
        The `WistiaMedia` that was deleted. `nil` if there was no match.

     */
    public func deleteMedia(mediaHashedID: String, completionHandler: (success: Bool, deletedMedia: WistiaMedia?)->() ) {
        let params:[String: AnyObject] = ["api_password" : apiToken]

        Alamofire.request(.DELETE, "\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID).json", parameters: params)
            .responseJSON(completionHandler: { (response) in
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        
                        if let
                            JSON = value as? [String: AnyObject],
                            media = ModelBuilder.mediaFromHash(JSON) where response.response?.statusCode == 200 {
                            completionHandler(success: true, deletedMedia: media)
                        }
                        
                    // Failure, provide an empty result
                    case .Failure(let error):
                        completionHandler(success: true, deletedMedia: nil)
                }
                
            })
    }

    // Copy

    /**
     Copy a piece of media, optionally moving to a new project or changing ownership.

     The returned `WistiaMedia` represents the *new copy* of the media.

     See [Wistia Data API - Medias: Copy](https://wistia.com/doc/data-api#medias_copy).

     - Parameter mediaHashedID: The unique `hashedID` of the media you want to copy.
     - Parameter projectID: The ID of the project where you want the new copy placed. If this value is invalid or omitted,
        defaults to the source media's current project.
     - Parameter owner: An email address specifying the owner of the new media. If this value is invalid or omitted, 
        defaults to the source media's current owner.
     - Parameter completionHandler: The block to invoke when the API call completes.
        The block takes two arguments: \
        `success`\
        True if the media was copied. \
        `copiedMedia` \
        The newly created `WistiaMedia`; a copy of the media specified by hashed ID.  `nil` if unsuccessful.

     */
    public func copyMedia(mediaHashedID: String, projectID: String?, owner: String?, completionHandler: (success: Bool, copiedMedia: WistiaMedia?)->() ) {
        var params:[String: AnyObject] = ["api_password" : apiToken]
        if let p = projectID {
            params["project_id"] = p
        }
        if let o = owner {
            params["owner"] = o
        }

        Alamofire.request(.POST, "\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID)/copy.json", parameters: params)
            .responseJSON(completionHandler: { (response) in
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        
                        if let
                            JSON = value as? [String: AnyObject],
                            media = ModelBuilder.mediaFromHash(JSON) where response.response?.statusCode == 201 {
                            completionHandler(success: true, copiedMedia: media)
                        }
                        
                    // Failure, provide an empty result
                    case .Failure(let error):
                        completionHandler(success: true, copiedMedia: nil)
                }
                
            })
    }

    // Stats

    /**
     Get aggregated tracking statistics for a video that has been embedded on your site.
     
     The `WistiaMedia` returned will include a `WistiaMediaStats` object with the statistics.
     
     See [Wistia Data API - Medias: Stats](https://wistia.com/doc/data-api#medias_stats).
     
     - Parameter mediaHashedID: The unique `hashedID` of the media for which you want statistics.
     - Parameter completionHandler: The block to invoke when the API call completes.
        The block takes one argument: \
        `media` \
        The `WistiaMedia` for which stats were requested. `nil` if there was no match.

    */
    public func statsForMedia(mediaHashedID: String, completionHandler: (media: WistiaMedia?)->() ) {
        let params:[String: AnyObject] = ["api_password" : apiToken]

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID)/stats.json", parameters: params)
            .responseJSON { (response) in
                
                // 'Swift-like' way to handle Alamofire responses
                switch response.result {
                    
                    // Success! Let's parse that JSON.
                    case .Success(let value):
                        
                        if let
                            JSON = value as? [String: AnyObject],
                            media = ModelBuilder.mediaFromHash(JSON) {
                            completionHandler(media: media)
                            
                    }
                        
                    // Failure, provide an empty result
                    case .Failure(let error):
                        completionHandler(media: nil)
                }
        }
    }

}
