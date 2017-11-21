#
# Be sure to run `pod lib lint WistiaKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WistiaKit'
  s.version          = '2.0.1'
  s.summary          = 'Access and playback your Wistia media.'

  s.description      = <<-DESC
A lightweight framework to access and playback your media.  Taking advantage of Swift 4, the web-based Vulcan player, and experience gained from The Original WistiaKit (tm).
                       DESC

  s.homepage         = 'https://github.com/wistia/WistiaKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'spinosa' => 'spinosa@gmail.com' }
  s.source           = { :git => 'https://github.com/wistia/WistiaKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/wistia'

  s.ios.deployment_target = '11.0'

  s.source_files = 'WistiaKit/Classes/**/*'

  s.frameworks = 'AVFoundation', 'AVKit'
end
