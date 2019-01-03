source 'https://github.com/CocoaPods/Specs.git'
source 'http://code.hh-medic.com/hh_public/HHDoctorSDK.ios.git'
platform :ios, ‘9.0’
use_frameworks!
inhibit_all_warnings!
install! 'cocoapods', :deterministic_uuids => false
target 'HPHeather' do
  pod 'RxCocoa'
  pod 'SnapKit'
  pod 'mob_sharesdk'
  pod 'SwiftyJSON'
  pod 'HHDoctorSDK', :git => "http://code.hh-medic.com/hh_public/HHDoctorSDK.ios.git", :branch => 'no/utdid'
  # UI模块(非必须，需要用到ShareSDK提供的分享菜单栏和分享编辑页面需要以下1行)
  pod 'mob_sharesdk/ShareSDKUI'
 # 平台SDK模块(对照一下平台，需要的加上。如果只需要QQ、微信、新浪微博，只需要以下3行)
  pod 'mob_sharesdk/ShareSDKPlatforms/WeChatFull'
  pod 'AlipaySDK-iOS'
end
