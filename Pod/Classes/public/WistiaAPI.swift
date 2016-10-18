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

    fileprivate static let APIBaseURL = "https://api.wistia.com/v1"
    fileprivate static let APIUploadURL = "https://upload.wistia.com"

    fileprivate let apiToken:String

    //MARK: - Initialization

    /**
     Initialize the `WistiaAPI` with the access permissions as granted by the given `apiToken`.

     - Parameter apiToken: The API Token that will be used to access the [Wistia Data API](http://wistia.com/doc/data-api).
     */
    public init(apiToken:String) {
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
        case name = "name"

        /// Sort the MediaCount property of the objects.
        case mediaCount = "mediaCount"

        /// Sort by the created date of the objects.
        case created = "created"

        /// Sort by the updated date of the objects.
        case updated = "updated"
    }

    /**
     Choice of direction when sorting.
     
     - `Descending`: Sort with the largest value or most-recent date first. Values decreasing as you move forward in the list.
     - `Ascending`: Sort the the smallest value or oldest date first.  Values increasing as you move forward in the list.
     */
    public enum SortDirection: Int {
        /// Sort with the largest value or most-recent date first. Values decreasing as you move forward in the list.
        case descending = 0

        /// Sort the the smallest value or oldest date first.  Values increasing as you move forward in the list.
        case ascending = 1
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
    public func showAccount(_ completionHander: @escaping (_ account: WistiaAccount?) -> () ){
        let params: [String : Any] = ["api_password" : apiToken]

        Alamofire.request("\(WistiaAPI.APIBaseURL)/account.json", method: .get, parameters: params)
            .responseJSON { response in

                switch(response.result) {
                case.success(let value):
                    if let JSON = value as? [String: Any],
                        let account = WistiaAccount(from: JSON) {
                        completionHander(account)
                    } else {
                        completionHander(nil)
                    }
                case .failure(_):
                    completionHander(nil)
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
    public func listProjects(page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)? = nil, completionHandler: @escaping (_ projects:[WistiaProject])->() ) {
        let params = WistiaAPI.addSorting(sorting, to: ["page" : page, "per_page" : perPage, "api_password" : apiToken])

        Alamofire.request("\(WistiaAPI.APIBaseURL)/projects.json", method: .get, parameters: params)
            .responseJSON { response in

                switch (response.result) {
                case .success(let value):
                    if let JSON = value as? [[String: Any]] {
                        var projects = [WistiaProject]()
                        for projectHash in JSON {
                            if let p = WistiaProject(from: projectHash) {
                                projects.append(p)
                            }
                        }
                        completionHandler(projects)

                    } else {
                        completionHandler([])
                    }
                case .failure(_):
                    completionHandler([])
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
    public func showProject(forHash projectHashedID: String, completionHandler: @escaping (_ project: WistiaProject?)->() ) {
        let params:[String: Any] = ["api_password" : apiToken]

        Alamofire.request("\(WistiaAPI.APIBaseURL)/projects/\(projectHashedID).json", method: .get, parameters: params)
            .responseJSON { (response) in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let project = WistiaProject(from: JSON) {
                        completionHandler(project)

                    } else {
                        completionHandler(nil)
                    }
                case .failure(_):
                    completionHandler(nil)
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
    public func createProject(named name: String, adminEmail: String?, anonymousCanUpload: Bool?, anonymousCanDownload: Bool?, isPublic: Bool?, completionHandler: @escaping (_ project: WistiaProject?)->() ) {
        var params:[String: Any] = ["api_password" : apiToken]
        updateParamsWith(&params, name: name, adminEmail: adminEmail, anonymousCanUpload: anonymousCanUpload, anonymousCanDownload: anonymousCanDownload, isPublic: isPublic)


        Alamofire.request("\(WistiaAPI.APIBaseURL)/projects.json", method: .post, parameters: params)
            .responseJSON { (response) in
                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let project = WistiaProject(from: JSON) {
                        completionHandler(project)

                    } else {
                        completionHandler(nil)
                    }
                case .failure(_):
                    completionHandler(nil)
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
    public func updateProject(forHash projectHashedID: String, withName name: String?, anonymousCanUpload: Bool?, anonymousCanDownload: Bool?, isPublic: Bool?, completionHandler: @escaping (_ success: Bool, _ updatedProject: WistiaProject?)->() ) {
        var params:[String: Any] = ["api_password" : apiToken]
        updateParamsWith(&params, name: name, adminEmail: nil, anonymousCanUpload: anonymousCanUpload, anonymousCanDownload: anonymousCanDownload, isPublic: isPublic)

        Alamofire.request("\(WistiaAPI.APIBaseURL)/projects/\(projectHashedID).json", method: .put, parameters: params)
            .responseJSON(completionHandler: { (response) in
                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let project = WistiaProject(from: JSON), response.response?.statusCode == 200 {
                        completionHandler(true, project)
                    } else {
                        completionHandler(true, nil)
                    }
                case .failure(_):
                    completionHandler(false, nil)
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
    public func deleteProject(forHash projectHashedID: String, completionHandler: @escaping (_ success: Bool, _ deletedProject: WistiaProject?)->() ) {
        let params:[String: Any] = ["api_password" : apiToken]

        Alamofire.request("\(WistiaAPI.APIBaseURL)/projects/\(projectHashedID).json", method: .delete, parameters: params)
            .responseJSON(completionHandler: { (response) in

                switch response.result {
                case .success(let value):
                    if response.response?.statusCode == 200 {
                        if let JSON = value as? [String: Any],
                            let project = WistiaProject(from: JSON) {
                            completionHandler(true, project)
                            return
                        }
                    }
                    completionHandler(true, nil)
                case .failure(_):
                    completionHandler(false, nil)
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
    public func copyProject(forHash projectHashedID: String, withUpdatedAdminEmail adminEmail: String?, completionHandler: @escaping (_ success: Bool, _ newProject: WistiaProject?)->() ) {
        var params:[String: Any] = ["api_password" : apiToken]
        updateParamsWith(&params, name: nil, adminEmail: adminEmail, anonymousCanUpload: nil, anonymousCanDownload: nil, isPublic: nil)

        Alamofire.request("\(WistiaAPI.APIBaseURL)/projects/\(projectHashedID)/copy.json", method: .post, parameters: params)
            .responseJSON(completionHandler: { (response) in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let project = WistiaProject(from: JSON), response.response?.statusCode == 201 {
                        completionHandler(true, project)
                    } else {
                        completionHandler(true, nil)
                    }
                case .failure(_):
                    completionHandler(false, nil)
                }

            })
    }


    //--- Helpers ---
    fileprivate func updateParamsWith(_ params: inout [String: Any], name: String?, adminEmail: String?, anonymousCanUpload: Bool?, anonymousCanDownload: Bool?, isPublic: Bool?) {
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
    public func listMediasGroupedByProject(page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)? = nil, limitedToProject project: WistiaProject? = nil, completionHandler: @escaping (_ projects:[WistiaProject])->() ) {
        var params = WistiaAPI.addSorting(sorting, to: ["page" : page, "per_page" : perPage, "api_password" : apiToken])
        if let proj = project {
            params["project_id"] = proj.projectID
        }

        Alamofire.request("\(WistiaAPI.APIBaseURL)/medias.json", method: .get, parameters: params)
            .responseJSON { response in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [[String: Any]] {
                        var projectsByHashedID = [String: WistiaProject]()

                        for mediaHash in JSON {
                            //1) Make Media
                            if let media = WistiaMedia.create(from: mediaHash) {

                                //2) Find project it's in (or create it anew)
                                if let projectHash = mediaHash["project"] as? [String: AnyObject], var project = WistiaProject(from: projectHash) {
                                    if projectsByHashedID.index(forKey: project.hashedID) == nil {
                                        project.medias = [WistiaMedia]()
                                        projectsByHashedID[project.hashedID] = project
                                    }
                                    //3) add media to project it's in
                                    projectsByHashedID[project.hashedID]!.medias!.append(media)
                                }
                            }

                        }
                        completionHandler(Array(projectsByHashedID.values))
                        
                    } else {
                        completionHandler([])
                    }
                case .failure(_):
                    completionHandler([])
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
    public func listMedias(page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)? = nil, filterByProject project: WistiaProject? = nil, filterByName name: String? = nil, filterByType type: String? = nil, filterByHashedID hashedID: String? = nil, completionHandler: @escaping (_ medias:[WistiaMedia])->() ) {
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

        Alamofire.request("\(WistiaAPI.APIBaseURL)/medias.json", method: .get, parameters: params)
            .responseJSON { response in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [[String: Any]] {
                        var medias = [WistiaMedia]()

                        for mediaHash in JSON {
                            if let media = WistiaMedia.create(from: mediaHash) {
                                medias.append(media)
                            }
                        }
                        completionHandler(medias)

                    } else {
                        completionHandler([])
                    }
                case .failure(_):
                    completionHandler([])
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
    public func showMedia(forHash mediaHashedID: String, completionHandler: @escaping (_ media: WistiaMedia?)->() ) {
        let params:[String: Any] = ["api_password" : apiToken]

        Alamofire.request("\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID).json", method: .get, parameters: params)
            .responseJSON { (response) in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let media = WistiaMedia.create(from: JSON) {
                        completionHandler(media)

                    } else {
                        completionHandler(nil)
                    }
                case .failure(_):
                    completionHandler(nil)
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
    public func updateMedia(forHash mediaHashedID: String, withName name: String?, newStillMediaId: String?, description: String?, completionHandler: @escaping (_ success: Bool, _ updatedMedia: WistiaMedia?)->() ) {
        var params:[String: Any] = ["api_password" : apiToken]
        if let n = name {
            params["name"] = n
        }
        if let nsmi = newStillMediaId {
            params["new_still_media_id"] = nsmi
        }
        if let d = description {
            params["description"] = d
        }

        Alamofire.request("\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID).json", method: .put, parameters: params)
            .responseJSON(completionHandler: { (response) in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let media = WistiaMedia.create(from: JSON), response.response?.statusCode == 200 {
                        completionHandler(true, media)
                    } else {
                        completionHandler(true, nil)
                    }
                case .failure(_):
                    completionHandler(false, nil)
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
    public func deleteMedia(forHash mediaHashedID: String, completionHandler: @escaping (_ success: Bool, _ deletedMedia: WistiaMedia?)->() ) {
        let params:[String: Any] = ["api_password" : apiToken]

        Alamofire.request("\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID).json", method: .delete, parameters: params)
            .responseJSON(completionHandler: { (response) in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let media = WistiaMedia.create(from: JSON), response.response?.statusCode == 200 {
                        completionHandler(true, media)
                    } else {
                        completionHandler(true, nil)
                    }
                case .failure(_):
                    completionHandler(false, nil)
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
    public func copyMedia(forHash mediaHashedID: String, toProject projectID: String?, withNewOwner owner: String?, completionHandler: @escaping (_ success: Bool, _ copiedMedia: WistiaMedia?)->() ) {
        var params:[String: Any] = ["api_password" : apiToken]
        if let p = projectID {
            params["project_id"] = p
        }
        if let o = owner {
            params["owner"] = o
        }

        Alamofire.request("\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID)/copy.json", method: .post, parameters: params)
            .responseJSON(completionHandler: { (response) in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let media = WistiaMedia.create(from: JSON), response.response?.statusCode == 201 {
                        completionHandler(true, media)
                    } else {
                        completionHandler(true, nil)
                    }
                case .failure(_):
                    completionHandler(false, nil)
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
    public func statsForMedia(forHash mediaHashedID: String, completionHandler: @escaping (_ media: WistiaMedia?)->() ) {
        let params:[String: Any] = ["api_password" : apiToken]

        Alamofire.request("\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID)/stats.json", method: .get, parameters: params)
            .responseJSON { (response) in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let media = WistiaMedia.create(from: JSON) {
                        completionHandler(media)

                    } else {
                        completionHandler(nil)
                    }
                case .failure(_):
                    completionHandler(nil)
                }

        }
    }

}

//MARK: - Customizations
extension WistiaAPI {

    /// Show the customizations configured for a particular `WistiaMedia` in your account.  These
    /// customizations are also known as "embed options" (a legacy misnomer from the days when these
    /// appearance and behavioral tweaks only applied as to a web embedded video).
    ///
    /// See [Wistia Data API - Customizations: Show](https://wistia.com/doc/data-api#customizations_show)
    ///
    /// - Note: The **options returned are a subset** of the full customizations available.  The options returned,
    ///     and those available in `WistiaMediaEmbedOtions`, are only those that apply to WistiaKit.
    ///     **If you would like to see the full set handled, please create a GitHub issue.**
    ///
    /// - Parameters:
    ///   - mediaHashedID: The unique `hashedID` of the media for which you want to see customizations.
    ///   - completionHandler: The block to invoke when the API call completes.
    ///    - embedOptions: The `WistiaMediaEmbedOptions` for the requested media.  `nil` if there was no match.
    public func showCustomizations(forHash mediaHashedID: String, completionHandler: @escaping (_ embedOptions: WistiaMediaEmbedOptions?)->() ) {
        let params: [String: Any] = ["api_password" : apiToken]

        Alamofire.request("\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID)/customizations.json", method: .get, parameters: params)
            .responseJSON { response in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let embedOptions = WistiaMediaEmbedOptions(from: JSON) {
                        completionHandler(embedOptions)
                    } else {
                        completionHandler(nil)
                    }
                case .failure(_):
                    completionHandler(nil)
                }
        }

    }

    /// Replace the customization options for a given media.
    ///
    /// **This is the only way to update customizations (aka embed options).**  WistiaKit does
    /// not support the customizations/update route due to the necessary added complexity in the
    /// current design and similar support being available using customizations/show+create.
    ///
    ///
    /// See [Wistia Data API - Customizations: Create](https://wistia.com/doc/data-api#customizations_create)
    ///
    /// - Parameters:
    ///   - embedOptions: The new customization options
    ///   - mediaHashedID: The `hashedID` of the media for which you want to replace customizations.
    ///   - completionHandler: The block to invoke when the API call completes.
    ///    - createdEmbedOptions: The newly created `WistiaMediaEmbedOptions` for the specified media.  `nil` if there was an error.
    public func createCustomizations(_ embedOptions: WistiaMediaEmbedOptions, forHash mediaHashedID: String, completionHandler: @escaping (_ createdEmbedOptions: WistiaMediaEmbedOptions?)->() ) {
        var params: [String: Any] = embedOptions.toJson()
        params["api_password"] = apiToken

        Alamofire.request("\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID)/customizations.json", method: .post, parameters: params, encoding: JSONEncoding.default)
            .responseJSON { response in

                switch response.result {
                case .success(let value):
                    if let JSON = value as? [String: Any],
                        let embedOptions = WistiaMediaEmbedOptions(from: JSON),
                        JSON["error"] == nil {
                        completionHandler(embedOptions)
                    } else {
                        completionHandler(nil)
                    }
                case .failure(_):
                    completionHandler(nil)
                }
        }

    }

    public func deleteCustomizations(forHash mediaHashedID: String, completionHandler: @escaping (_ success: Bool)->() ) {
        let params: [String: Any] = ["api_password" : apiToken]

        Alamofire.request("\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID)/customizations.json", method: .delete, parameters: params)
            .response { response in

                if response.response?.statusCode == 200 {
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }

        }
        
    }

}

//MARK: - Uploading
extension WistiaAPI {

    /// Upload media to your Wistia account.
    ///
    /// Uploaded media will be visible immediately in your account, but may require processing (as is the case for uploads in general).
    /// Indeed, the `WistiaMedia` returned to your completion handler will generally have no `WistiaAsset`s; some processing time is
    /// required to generate the assets.
    ///
    /// - Parameters:
    ///   - fileURL: The device-local `URL` of the video to upload to your account.
    ///   - project: The `WistiaProject` to upload media into. If omitted, a new project will be created and uploaded to.
    ///      The naming convention used for such projects is Uploads_YYYY-MM-DD.
    ///   - name: A display name to use for the media in Wistia. If omitted, the filename will be used instead.
    ///   - description: A description to use for the media in Wistia. You can use basic HTML here,
    ///      but note that both HTML and CSS will be sanitized.
    ///   - contactID: A Wistia contact id. If omitted, it will default to the contact_id of the account's owner.
    ///   - progressHandler: A block that will be called periodically during the upload.
    ///    - progress: An object reporting the progress of data being read by the server.
    ///   - completionHandler: The block to invoke when the upload call completes.
    ///    - media: The newly created `WistiaMedia`, or `nil` if there was a problem uploading.
    public func upload(fileURL: URL, into project: WistiaProject? = nil, name: String? = nil, description: String? = nil, contactID: Int? = nil, progressHandler: ((_ progress: Progress) -> Void)?, completionHandler: @escaping (_ media: WistiaMedia?) -> Void) {

        upload(data: nil, fileURL: fileURL, into: project?.hashedID, name: name, description: description, contactID: contactID, progressHandler: progressHandler, completionHandler: completionHandler)
    }

    /// Upload media to your Wistia account.
    ///
    /// Uploaded media will be visible immediately in your account, but may require processing (as is the case for uploads in general).
    /// Indeed, the `WistiaMedia` returned to your completion handler will generally have no `WistiaAsset`s; some processing time is
    /// required to generate the assets.
    ///
    /// - Parameters:
    ///   - fileURL: The device-local `URL` of the video to upload to your account.
    ///   - projectHashedID: The hashed id of the project to upload media into. If omitted, a new project will be created and uploaded to.
    ///      The naming convention used for such projects is Uploads_YYYY-MM-DD.
    ///   - name: A display name to use for the media in Wistia. If omitted, the filename will be used instead.
    ///   - description: A description to use for the media in Wistia. You can use basic HTML here,
    ///      but note that both HTML and CSS will be sanitized.
    ///   - contactID: A Wistia contact id. If omitted, it will default to the contact_id of the account's owner.
    ///   - progressHandler: A block that will be called periodically during the upload.
    ///    - progress: An object reporting the progress of data being read by the server.
    ///   - completionHandler: The block to invoke when the upload call completes.
    ///    - media: The newly created `WistiaMedia`, or `nil` if there was a problem uploading.
    public func upload(fileURL: URL, into projectHashedID: String? = nil, name: String? = nil, description: String? = nil, contactID: Int? = nil, progressHandler: ((_ progress: Progress) -> Void)?, completionHandler: @escaping (_ media: WistiaMedia?) -> Void) {

        upload(data: nil, fileURL: fileURL, into: projectHashedID, name: name, description: description, contactID: contactID, progressHandler: progressHandler, completionHandler: completionHandler)
    }

    /// Upload media to your Wistia account.
    ///
    /// Uploaded media will be visible immediately in your account, but may require processing (as is the case for uploads in general).
    /// Indeed, the `WistiaMedia` returned to your completion handler will generally have no `WistiaAsset`s; some processing time is
    /// required to generate the assets.
    ///
    /// - Parameters:
    ///   - data: The video to upload to your account.
    ///   - project: The `WistiaProject` to upload media into. If omitted, a new project will be created and uploaded to.
    ///      The naming convention used for such projects is Uploads_YYYY-MM-DD.
    ///   - name: A display name to use for the media in Wistia. If omitted, the filename will be used instead.
    ///   - description: A description to use for the media in Wistia. You can use basic HTML here,
    ///      but note that both HTML and CSS will be sanitized.
    ///   - contactID: A Wistia contact id. If omitted, it will default to the contact_id of the account's owner.
    ///   - progressHandler: A block that will be called periodically during the upload.
    ///    - progress: An object reporting the progress of data being read by the server.
    ///   - completionHandler: The block to invoke when the upload call completes.
    ///    - media: The newly created `WistiaMedia`, or `nil` if there was a problem uploading.
    public func upload(data:Data, into project: WistiaProject? = nil, name: String? = nil, description: String? = nil, contactID: Int? = nil, progressHandler: ((_ progress: Progress) -> Void)?, completionHandler: @escaping (_ media: WistiaMedia?) -> Void) {

        upload(data: data, fileURL: nil, into: project?.hashedID, name: name, description: description, contactID: contactID, progressHandler: progressHandler, completionHandler: completionHandler)
    }

    /// Upload media to your Wistia account.
    ///
    /// Uploaded media will be visible immediately in your account, but may require processing (as is the case for uploads in general).
    /// Indeed, the `WistiaMedia` returned to your completion handler will generally have no `WistiaAsset`s; some processing time is
    /// required to generate the assets.
    ///
    /// - Parameters:
    ///   - data: The video to upload to your account.
    ///   - projectHashedID: The hashed id of the project to upload media into. If omitted, a new project will be created and uploaded to. 
    ///      The naming convention used for such projects is Uploads_YYYY-MM-DD.
    ///   - name: A display name to use for the media in Wistia. If omitted, the filename will be used instead.
    ///   - description: A description to use for the media in Wistia. You can use basic HTML here,
    ///      but note that both HTML and CSS will be sanitized.
    ///   - contactID: A Wistia contact id. If omitted, it will default to the contact_id of the account's owner.
    ///   - progressHandler: A block that will be called periodically during the upload.
    ///    - progress: An object reporting the progress of data being read by the server.
    ///   - completionHandler: The block to invoke when the upload call completes.
    ///    - media: The newly created `WistiaMedia`, or `nil` if there was a problem uploading.
    public func upload(data:Data, into projectHashedID: String? = nil, name: String? = nil, description: String? = nil, contactID: Int? = nil, progressHandler: ((_ progress: Progress) -> Void)?, completionHandler: @escaping (_ media: WistiaMedia?) -> Void) {

        upload(data: data, fileURL: nil, into: projectHashedID, name: name, description: description, contactID: contactID, progressHandler: progressHandler, completionHandler: completionHandler)
    }

    fileprivate func upload(data: Data?, fileURL: URL?, into projectHashedID: String? = nil, name: String? = nil, description: String? = nil, contactID: Int? = nil, progressHandler: ((Progress) -> Void)?, completionHandler: @escaping (WistiaMedia?) -> Void) {

        guard (data != nil && fileURL == nil) || (data == nil && fileURL != nil)
            else { return assertionFailure("Must pass exactly one data or file, not both") }

        Alamofire.upload(
            multipartFormData: { multipartFormData in
                if let d = data {
                    multipartFormData.append(d, withName: "ignored")
                }
                if let f = fileURL {
                    multipartFormData.append(f, withName: "ignored")
                }
                multipartFormData.append(self.apiToken.data(using: .utf8)!, withName: "api_password")
                if let pID = projectHashedID,
                    let data = pID.data(using: .utf8) {
                    multipartFormData.append(data, withName: "project_id")
                }
                if let n = name,
                    let data = n.data(using: .utf8) {
                    multipartFormData.append(data, withName: "name")
                }
                if let d = description,
                    let data = d.data(using: .utf8) {
                    multipartFormData.append(data, withName: "description")
                }
                if let cID = contactID,
                    let data = "\(cID)".data(using: .utf8) {
                    multipartFormData.append(data, withName: "contact_id")
                }
            },

            usingThreshold: 10_000_000, //files over 10MB will be streamed from disk instead of converted in memory

            to: WistiaAPI.APIUploadURL,

            encodingCompletion: { encodingResult in
                switch encodingResult {

                case .success(let upload, _, _):
                    if let prog = progressHandler {
                        upload.uploadProgress(closure: prog)
                    }

                    upload.responseJSON { response in
                        switch response.result {
                        case .success(let value):
                            if let JSON = value as? [String: Any],
                                let media = WistiaMedia.create(from: JSON), response.response?.statusCode == 200 {
                                completionHandler(media)
                            } else {
                                completionHandler(nil)
                            }
                        case .failure(_):
                            completionHandler(nil)
                        }
                    }

                case .failure(let encodingError):
                    print(encodingError)
                }
            })

    }

}
