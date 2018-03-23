Pod::Spec.new do |s|
  s.name           = "YMPhotoBrowser"
  s.version        = "1.0.0"
  s.summary        = "YMPhotoBrowser is a modern looking photo gallery written in Swift for iOS."
  s.homepage       = "https://github.com/zyuanming/YMPhotoBrowser"
  s.license        = { :type => 'MIT', :file => 'LICENSE' }
  s.author         = { "zyuanming" => "zyuanming@outlook.com" }
  s.swift_version  = '4.0'
  s.ios.deployment_target = '8.0'
  s.source         = { :git => "https://github.com/zyuanming/YMPhotoBrowser.git", :tag => "#{s.version}" }
  s.source_files   = "YMPhotoBrowser/*"
  s.resource_bundles = { 'Image' => ['YMPhotoBrowser/Resources/*.png']}
  s.dependency 'Kingfisher', '~> 4.5.0'
end