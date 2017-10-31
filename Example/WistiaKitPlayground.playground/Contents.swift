import UIKit
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////






WistiaClient.default = WistiaClient(token: "COPY_TOKEN_FROM_ACCOUNT_SETTINGS")
let projectId = "HASHED_ID_OF_A_PROJECT_WITH_MEDIA_IN_IT"
let mediaId = "HASHED_ID_OF_A_MEDIA"

Project.list { (projects, error) in
    if let projects = projects {
        for project in projects {
            Media.list(projectID: project.id!, { (medias, error) in
                if let medias = medias {
                    print("Project [\(project.id!)] contains \(project.attributes?.videoCount ?? 99) medias:")
                    for media in medias {
                        print("  media: \(media.id!)")
                    }
                }
                else if let error = error {
                    print("Project [\(project.id!)] had an error reading media: \(error)")
                }
            })

        }
    }
    else if let error = error {
        print("Error reading project: \(error)")
    }
}

Media.list(projectID: projectId) { (medias, error) in
    if let medias = medias {
        print("Listing medias: \(String(describing: medias))")
    } else {
        print("Error listing medias: \(error!)")
    }
}

Media(id: mediaId).show { (media, error) in
    if let media = media {
        print("Showing one media: \(String(describing: media))")
    } else {
        print("Error showing media: \(error!)")
    }
}







/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {
    PlaygroundPage.current.finishExecution()
}
