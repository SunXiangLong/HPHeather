//
//  AppDelegate.swift
//  HPHeather
//
//  Created by zhuge on 2018/12/31.
//  Copyright © 2018年 诸葛找房. All rights reserved.
//

import UIKit
import HHDoctorSDK
let appId = "wx77c4f94de7b14883"
let appSecret = "7ad4186d6218d2d5b3787b6321d5364b"
let productId = "8255"
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        WXApi.registerApp(appId)
        ShareSDK.registPlatforms{
            $0?.setupWeChat(withAppId: appId, appSecret: appSecret)
        }
        let option = HHSDKOptions(productId: productId, isDebug: false, isDevelop: false)
        HHMSDK.default.start(option: option)
        return true
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AlipaySDK.defaultService()?.processOrder(withPaymentResult: url, standbyCallback: { (value) in
            NotificationCenter.default.post(Notification.init(name: Notification.Name(rawValue: "AlipayPay"), object: nil, userInfo: value))
        })
        return WXApi.handleOpen(url, delegate: self)
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        HHMSDK.default.updateAPNS(token: deviceToken)
    }
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}
//MARK: - WXApiDelegate
extension AppDelegate:WXApiDelegate{
    func onReq(_ req: BaseReq!) {
        print(req)
    }
    func onResp(_ resp: BaseResp!) {
        switch resp.className {
        case SendAuthResp.description():
            let authResp =  resp as!  SendAuthResp
            guard let code = authResp.code else { return  }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SendAuthRespCode"), object: nil, userInfo: ["code":code])
        case PayResp.description():
            let payResp = resp as!  PayResp
            switch payResp.errCode {
            case Int32(0):
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "WXPaySuccess"), object: nil, userInfo: nil)
            default:
                print("error")
            }
        default:
            print("---")
        }
    }
}
extension NSObject
{
    // MARK:返回className
    var className:String{
        get{
            let name =  type(of: self).description()
            if(name.contains(".")){
                return name.components(separatedBy: ".")[1];
            }else{
                return name;
            }
            
        }
    }
    
}

