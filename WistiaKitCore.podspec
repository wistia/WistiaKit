# WistiaKitCore is the lighter-weight lower-level foundation upon which
# the full WistiaKit pod is built.
#
# They are split into two individual Pods to allow for different
# module names (which isn't possible with subspecs).
Pod::Spec.new do |data|
  data.name             = "WistiaKitCore"
  data.module_name      = "WistiaKitCore"
  data.version          = "0.30.3"
  data.summary          = "Access all of your Wistia media."
  data.description      = <<-DESC
WistiaKitCore is the lighter-weight and lower-level foundation upon which the full WistiaKit is built.  It defines the Wistia object model and provides API access.  Playback and UI is provided by WistiaKit.

They are split into two individual Pods to allow for different module names (which isn't possible with subspecs).
                             DESC
  data.homepage         = "https://github.com/wistia/WistiaKit"
  data.license          = "MIT"
  data.author           = { "spinosa" => "spinosa@gmail.com" }
  data.source           = { :git => "https://github.com/wistia/WistiaKit.git", :tag => data.version.to_s }
  data.social_media_url = 'http://twitter.com/wistia'
  
  data.ios.deployment_target = '9.0'
  data.tvos.deployment_target = '9.0'
  data.requires_arc = true
  
  data.source_files = "Pod/Classes/Core/**/*"
  
  data.dependency 'Alamofire', '~> 4.7'
  
  data.frameworks = 'Foundation'
end
