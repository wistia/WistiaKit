//
//  WistiaAPI.swift
//  WistiaKit
//
//  Created by Daniel Spinosa on 1/25/16.
//  Copyright © 2016 Wistia, Inc. All rights reserved.
//

import Alamofire

public class WistiaAPI {

    private static let APIBaseURL = "https://api.wistia.com/v1"

    private let apiToken:String

    public init(apiToken:String) {
        self.apiToken = apiToken
    }

    public enum SortBy: String {
        case Name = "name",
        MediaCount = "mediaCount",
        Created = "created",
        Updated = "updated"
    }

    public enum SortDirection: Int {
        case Descending = 0,
        Ascending = 1
    }

}

//MARK: - Account
// http://wistia.com/doc/data-api#account
extension WistiaAPI {

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

    public func listProjects(page page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)?, completionHandler: (projects:[WistiaProject])->() ) {
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

    //Use the medias/list route but return medias organized by project
    //leave project nil to get for any/all projects
    public func listMediasGroupedByProject(page page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)?, limitedToProject project: WistiaProject? = nil, completionHandler: (projects:[WistiaProject])->() ) {
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

    public func listMedias(page page: Int = 1, perPage: Int = 10, sorting: (by: SortBy, direction: SortDirection)?, limitedToProject project: WistiaProject? = nil, completionHandler: (medias:[WistiaMedia])->() ) {
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
