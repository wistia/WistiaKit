# The full WistiaKit pod adds playback to the WistiaKitData pod
#
# They are split into two individual Pods to allow for different
# module names (which isn't possible with subspecs).
Pod::Spec.new do |s|
  s.name             = "WistiaKit"
  s.version          = "0.21.0"
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

  # s.subspec 'Data' do |data|
  #   data.source_files = "Pod/Classes/Data/**/*"
  #   data.module_name = "WistiaKitData"
  #
  #   data.dependency 'Alamofire', '~> 4.0'
  #
  #   data.frameworks = 'Foundation'
  # end
  
  # s.subspec 'Playback' do |playback|
  #   playback.dependency 'WistiaKit/Data'
  #
  #   playback.source_files = "Pod/Classes/Playback/**/*"
  #   # Although resource_bundles is the new recommended hotness, it doesn't play well with Asset Catalogs.
  #   # s.resource_bundles = {
  #   #   'Assets' => ['Pod/Assets/**/*.xcassets']
  #   # }
  #   # Fortunately, the old resources method will faithfully copy the catalog in such a way that it 'just works'
  #   playback.resources = 'Pod/Assets/**/*.xcassets'
  #
  #   # No xibs on tvOS
  #   playback.tvos.exclude_files = 'Pod/Classes/**/*.{xib,nib}'
  #
  #   playback.dependency 'AlamofireImage', '~> 3.0'
  #
  #   # No CoreMotion on tvOS
  #   playback.ios.frameworks =  'AdSupport', 'AVFoundation', 'AVKit', 'SceneKit', 'SpriteKit', 'UIKit', 'CoreMotion'
  #   playback.tvos.frameworks = 'AdSupport', 'AVFoundation', 'AVKit', 'SceneKit', 'SpriteKit', 'UIKit'
  # end
  
  s.dependency 'WistiaKitData'
  
  s.source_files = "Pod/Classes/Playback/**/*"
  # Although resource_bundles is the new recommended hotness, it doesn't play well with Asset Catalogs.
  # s.resource_bundles = {
  #   'Assets' => ['Pod/Assets/**/*.xcassets']
  # }
  # Fortunately, the old resources method will faithfully copy the catalog in such a way that it 'just works'
  s.resources = 'Pod/Assets/**/*.xcassets'

  # No xibs on tvOS
  s.tvos.exclude_files = 'Pod/Classes/**/*.{xib,nib}'
  
  s.dependency 'AlamofireImage', '~> 3.0'
  
  # No CoreMotion on tvOS
  s.ios.frameworks =  'WistiaKitData', 'AdSupport', 'AVFoundation', 'AVKit', 'SceneKit', 'SpriteKit', 'UIKit', 'CoreMotion'
  s.tvos.frameworks = 'WistiaKitData', 'AdSupport', 'AVFoundation', 'AVKit', 'SceneKit', 'SpriteKit', 'UIKit'

end
