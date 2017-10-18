import UIKit
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////






WistiaClient.default = WistiaClient(token: "COPY_TOKEN_FROM_ACCOUNT_SETTINGS")
let projectId = "HASHED_ID_OF_A_PROJECT_WITH_MEDIA_IN_IT"
let mediaId = "HASHED_ID_OF_A_MEDIA"

Media.list(projectID: projectId) { (medias, error) in
    print("Got medias: \(String(describing: medias))")
}

Media(id: mediaId).show { (media, error) in
    print("Got one media: \(String(describing: media))")
}







/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {
    PlaygroundPage.current.finishExecution()
}
