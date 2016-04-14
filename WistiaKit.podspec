#
# Be sure to run `pod lib lint WistiaKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "WistiaKit"
  s.version          = "0.1.1"
  s.summary          = "Access and playback all of your Wistia media"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
Wistia is a great web video host.  But why shackle ourselves to the world wide web?

With WistiaKit you can easily access and play back all of your Wistia hosted content natively on iOS.

We've built for you a beautiful high level view controller (like AVPlayerViewController) sitting atop a powerful lower level player (like AVPlayer) providing all of the power of Wistia on iOS.
                       DESC

  s.homepage         = "https://github.com/wistia/WistiaKit"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "spinosa" => "spinosa@gmail.com" }
  s.source           = { :git => "https://github.com/wistia/WistiaKit.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/wistia'

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'

  # Although resource_bundles is the new recommended hotness, it doens't play well with Asset Catalogs.
  # Fortunately, the old resources method will faithfully copy the catalog in such a way that it 'just works'
  s.resources = 'Pod/Assets/**/*.xcassets'
  #s.resource_bundles = {
  #   'Assets' => ['Pod/Assets/**/*.xcassets']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'AdSupport', 'AVFoundation', 'AVKit', 'CoreMotion', 'Foundation', 'SceneKit', 'SpriteKit', 'UIKit'
  s.dependency 'Alamofire', '~> 3.3'
  s.dependency 'AlamofireImage', '~> 2.4'
end
