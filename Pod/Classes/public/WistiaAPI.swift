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
    
}

//MARK: - Account
// http://wistia.com/doc/data-api#account
extension WistiaAPI {

    public func showAccount(completionHander: (account: WistiaAccount?) -> () ){
        let params: [String : AnyObject] = ["api_password" : apiToken]

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/account.json", parameters: params)
            .responseJSON { response in

                if let JSON = response.result.value as? [String: AnyObject] {
                    let account = ModelBuilder.accountFromHash(JSON)
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
    public func listProjects(page page: Int = 1, perPage: Int = 10 /* TODO: SORT */, completionHandler: (projects:[WistiaProject])->() ) {
        let params: [String : AnyObject] = ["page" : page, "per_page" : perPage, "api_password" : apiToken, "sort_by" : "updated", "sort_direction" : 1]

        Alamofire.request(.GET, "\(WistiaAPI.APIBaseURL)/projects.json", parameters: params)
            .responseJSON { response in

                if let JSON = response.result.value as? [[String: AnyObject]] {
                    var projects = [WistiaProject]()
                    for projectHash in JSON {
                        if let p = ModelBuilder.projectFromHash(projectHash) {
                            projects.append(p)
                        } else {
                            print("ERROR parsing project hash: \(projectHash)")
                        }
                    }
                    completionHandler(projects: projects)

                } else {
                    completionHandler(projects: [])
                }
            }
    }

}

//MARK: - Medias
// http://wistia.com/doc/data-api#medias
extension WistiaAPI {

    //Use the medias/list route but return medias organized by project
    //leave project nil to get for any/all projects
    public func listMediasGroupedByProject(page page: Int = 1, perPage: Int = 10 /* TODO: SORT */, limitedToProject project: WistiaProject? = nil, completionHandler: (projects:[WistiaProject])->() ) {
        var params: [String : AnyObject] = ["page" : page, "per_page" : perPage, "api_password" : apiToken]
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
}
