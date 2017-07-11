#
# Be sure to run `pod lib lint 'JXWebFile.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "JXWebFile"
  s.version          = "1.0.1"
  s.summary          = "A webFile downloader"
  s.homepage         = "https://github.com/zhujiaxiang/JXWebFile"
  s.license          = 'MIT'
  s.author           = { "朱佳翔" => "zjxbaozoudhm@gmail.com" }
  s.source           = { :git => "https://github.com/zhujiaxiang/JXWebFile.git", :tag => s.version.to_s }

  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.source_files  = "JXWebFile/**/*.{h,m}"
  s.public_header_files = "JXWebFile/**/*.h"

  s.dependency 'Masonry', '~> 1.0.0'
end
