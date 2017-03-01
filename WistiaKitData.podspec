# WistiaKitData is the lighter-weight lower-level foundation upon which
# the full WistiaKit pod is built.
#
# They are split into two individual Pods to allow for different
# module names (which isn't possible with subspecs).
Pod::Spec.new do |data|
  data.name             = "WistiaKitData"
  data.module_name      = "WistiaKitData"
  data.version          = "0.1.0"
  data.summary          = "TODO"
  data.description      = "TODO"
  data.homepage         = "TODO"
  data.license          = "MIT"
  data.author           = { "spinosa" => "spinosa@gmail.com" }
  data.source           = { :git => "https://github.com/wistia/WistiaKit.git", :tag => data.version.to_s }
  data.social_media_url = 'http://twitter.com/wistia'
  
  data.ios.deployment_target = '9.0'
  data.tvos.deployment_target = '9.0'
  data.requires_arc = true
  
  data.source_files = "Pod/Classes/Data/**/*"
  
  data.dependency 'Alamofire', '~> 4.0'
  
  data.frameworks = 'Foundation'
end