Pod::Spec.new do |spec|
  spec.name         = "IRMusicPlayer"
  spec.version      = "0.2.0"
  spec.summary      = "A powerful music player of iOS."
  spec.description  = "A powerful music player of iOS."
  spec.homepage     = "https://github.com/irons163/IRMusicPlayer.git"
  spec.license      = "MIT"
  spec.author       = "irons163"
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/irons163/IRMusicPlayer.git", :tag => spec.version.to_s }
  spec.source_files  = "IRMusicPlayer/**/*.{h,m}"
  spec.resources = ["IRMusicPlayer/**/*.xib", "IRMusicPlayer/**/*.xcassets"]
end
