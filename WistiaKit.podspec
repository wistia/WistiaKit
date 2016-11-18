#
# Be sure to run `pod lib lint WistiaKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "WistiaKit"
  s.version          = "0.17.1"
  s.summary          = "Access and playback all of your Wistia media"

  s.description      = <<-DESC
Wistia is a great web video host.  But why shackle ourselves to the world wide web?

With WistiaKit you can easily access and play back all of your Wistia hosted content natively on iOS and tvOS.

We've built for you a beautiful high level view controller (like AVPlayerViewController) sitting atop a powerful lower level player (like AVPlayer) providing all of the power of Wistia on iOS and tvOS.
                       DESC

  s.homepage         = "https://github.com/wistia/WistiaKit"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "spinosa" => "spinosa@gmail.com" }
  s.source           = { :git => "https://github.com/wistia/WistiaKit.git", :tag => s.version.to_s }
  s.social_media_url = 'http://twitter.com/wistia'

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'
  s.requires_arc = true

  s.ios.source_files = 'Pod/Classes/**/*'
  # TODO: s.tvos.exclude_files = [...] to remove the xibs instead of
  s.tvos.source_files = 'Pod/Classes/**/*.swift'

  # Although resource_bundles is the new recommended hotness, it doesn't play well with Asset Catalogs.
  # Fortunately, the old resources method will faithfully copy the catalog in such a way that it 'just works'
  # s.resource_bundles = {
  #   'Assets' => ['Pod/Assets/**/*.xcassets']
  # }
  s.resources = 'Pod/Assets/**/*.xcassets'


  # No CoreMotion on tvOS
  s.ios.frameworks = 'AdSupport', 'AVFoundation', 'AVKit', 'CoreMotion', 'Foundation', 'SceneKit', 'SpriteKit', 'UIKit'
  s.tvos.frameworks = 'AdSupport', 'AVFoundation', 'AVKit', 'Foundation', 'SceneKit', 'SpriteKit', 'UIKit'

  s.dependency 'Alamofire', '~> 4.0'
  s.dependency 'AlamofireImage', '~> 3.0'
end
