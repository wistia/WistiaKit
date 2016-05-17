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
 
 - TODO: The `WistiaAPI` is not yet feature complete.  You will see **TODO** comments for the work remaining.
 This warning will remain in the documentation until the class is complete.

 */
public class WistiaAPI {

    private static let APIBaseURL = "https://api.wistia.com/v1"

    private let apiToken:String

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

//MARK: - Account
extension WistiaAPI {

    /**
     Get account information.  
     
     See [Wistia Data API - Account](http://wistia.com/doc/data-api#account)
     
     - Parameters:
        - completionHandler: The block to invoke when the API call completes.
         The block takes one argument: \
        `account` \
        The `WistiaAccount` object created from the API response.

    */
    public func showAccount(completionHander: (account: WistiaAccount?) -> () ){
        let params: [String : AnyObject] = ["api_password" : apiToken]

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/account.json", parameters: params)
            .responseJSON { response in

                if let JSON = response.result.value as? [String: AnyObject],
                    account = ModelBuilder.accountFromHash(JSON) {
                    completionHander(account: account)
                } else {
                    completionHander(account: nil)
                }

            }
    }

}

//MARK: - Projects
// http://wistia.com/doc/data-api#projects
extension WistiaAPI {

    /**
     List the projects in your accont.  
     
     See [Wistia Data API - Projects: List](http://wistia.com/doc/data-api#projects_list).
     
     - Parameters:
        - page: The page of results to show.  Ex: `page` 2 with a `pageCount` of 10 will return results starting with the 11th object.
        - perPage: The number of results in a page.  This is the maximum number of results that may be returned in a single request.
        - sorting: A tuple specifying what attribute to sort by and the direction to sort in.
        - completionHandler: The block to invoke when the API call completes.
        The block takes one argument: \
        `projects` \
        An array of `WistiaProject` objects created from the API response.  May be empty.

     */
    public func listProjects(page page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)? = nil, completionHandler: (projects:[WistiaProject])->() ) {
        let params = WistiaAPI.addSorting(sorting, to: ["page" : page, "per_page" : perPage, "api_password" : apiToken])

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/projects.json", parameters: params)
            .responseJSON { response in

                if let JSON = response.result.value as? [[String: AnyObject]] {
                    var projects = [WistiaProject]()
                    for projectHash in JSON {
                        if let p = ModelBuilder.projectFromHash(projectHash) {
                            projects.append(p)
                        }
                    }
                    completionHandler(projects: projects)

                } else {
                    completionHandler(projects: [])
                }
            }
    }

    /**
     Retrieve details about a specific project.
     
     The returned `WistiaProject` will also include an array of `WistiaMedia` objects.
     
     See [Wistia Data API - Projects: Show](http://wistia.com/doc/data-api#projects_show).

     - Parameters:
        - projectHashedID: The unique `hashed ID` of the project for which you want details.
        - completionHandler: The block to invoke when the API call completes.
        The block takes one argument: \
        `project` \
        The `WistiaProject` specified. `nil` if there was no match.

     */
    public func showProject(projectHashedID: String, completionHandler: (project: WistiaProject?)->() ) {
        let params:[String: AnyObject] = ["api_password" : apiToken]

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/projects/\(projectHashedID).json", parameters: params)
            .responseJSON { (response) in
                if let JSON = response.result.value as? [String: AnyObject],
                    project = ModelBuilder.projectFromHash(JSON) {
                    completionHandler(project: project)

                } else {
                    completionHandler(project: nil)
                }
        }
    }

    //TODO: Create

    //TODO: Update

    //TODO: Delete

    //TODO: Copy

}

//MARK: - Medias
// http://wistia.com/doc/data-api#medias
extension WistiaAPI {

    /**
     List the media in your account.  Request media with paging and sorting applied to the media attributes, but
     instead of returning an array of media, group the media into their respective projects.

     See [Wistia Data API - Medias: List](http://wistia.com/doc/data-api#medias_list).
     
     - Note: Convenience method.  See `listMedias(page:perPage:sorting:limitedToProject:completionHandler:)` 
     for the direct mirror of the Data API method.

     - Parameters:
         - page: The page of results to show.  Ex: `page` 2 with a `pageCount` of 10 will return results starting with the 11th object.
         - perPage: The number of results in a page.  This is the maximum number of results that may be returned in a single request.
         - sorting: A tuple specifying what attribute to sort by and the direction to sort in.
         - limitedToProject: Limit results to `WistiaMedia` within this `WistiaProject`
         - completionHandler: The block to invoke when the API call completes.
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

                if let JSON = response.result.value as? [[String: AnyObject]] {
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

                } else {
                    completionHandler(projects: [])
                }
        }
    }

    /**
     List the media in your account.  Supports paging and filtering.
     
     See [Wistia Data API - Medias: List](http://wistia.com/doc/data-api#medias_list).
     
     - Note: Full filtering support is forthcoming.

     - Parameters:
         - page: The page of results to show.  Ex: `page` 2 with a `pageCount` of 10 will return results starting with the 11th object.
         - perPage: The number of results in a page.  This is the maximum number of results that may be returned in a single request.
         - sorting: A tuple specifying what attribute to sort by and the direction to sort in.
         - limitedToProject: Limit results to `WistiaMedia` within this `WistiaProject`
         - completionHandler: The block to invoke when the API call completes.
         The block takes one argument: \
         `medias` \
         An array of `WistiaMedia` objects returned by the API call.  Will be empty when request page starts beyond the last item.

     */
    public func listMedias(page page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)? = nil, limitedToProject project: WistiaProject? = nil, completionHandler: (medias:[WistiaMedia])->() ) {
        var params = WistiaAPI.addSorting(sorting, to: ["page" : page, "per_page" : perPage, "api_password" : apiToken])
        if let proj = project {
            params["project_id"] = proj.projectID
        }

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/medias.json", parameters: params)
            .responseJSON { response in

                if let JSON = response.result.value as? [[String: AnyObject]] {
                    var medias = [WistiaMedia]()

                    for mediaHash in JSON {
                        if let media = ModelBuilder.mediaFromHash(mediaHash) {
                            medias.append(media)
                        }
                    }
                    completionHandler(medias: medias)

                } else {
                    completionHandler(medias: [])
                }
        }
    }

    /**
     Retrieve details about a specific media.


     See [Wistia Data API - Medias: Show](http://wistia.com/doc/data-api#medias_show).

     - Parameters:
        - mediaHashedID: The unique `hashed ID` of the media for which you want details.
         - completionHandler: The block to invoke when the API call completes.
         The block takes one argument: \
         `media` \
         The `WistiaMedia` specified. `nil` if there was no match.

     */
    public func showMedia(mediaHashedID: String, completionHandler: (media: WistiaMedia?)->() ) {
        let params:[String: AnyObject] = ["api_password" : apiToken]

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/medias/\(mediaHashedID).json", parameters: params)
            .responseJSON { (response) in
                if let JSON = response.result.value as? [String: AnyObject],
                    media = ModelBuilder.mediaFromHash(JSON) {
                    completionHandler(media: media)

                } else {
                    completionHandler(media: nil)
                }
        }
    }

    //TODO: Update

    //TODO: Delete

    //TODO: Copy

    //TODO: Stats
}
