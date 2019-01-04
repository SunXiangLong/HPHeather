//
//  HPHeather.swift
//  XMBHPHealthModule
//
//  Created by zhuge on 2018/12/29.
//

import UIKit
import WebKit
import RxCocoa
import RxSwift
import RxAtomic
import SnapKit
import SwiftyJSON
import HHDoctorSDK
let indexUrl = "https://www.mabao75.com/index?e=xmb"
let categoryUrl = "https://www.mabao75.com/category?e=xmb"
let homeUrl = "https://www.mabao75.com/home?e=xmb"
class HPHeather: UIViewController {
    var url  = URL(string: indexUrl)
    var paySuccessUrl:URL?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        addScriptMessageHandler()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        removeScriptMessageHandler()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        subscribe()
        guard let url = self.url else { return  }
        self.webView.load(URLRequest(url: url))
    }
    
    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        configuration.preferences = WKPreferences()
        configuration.preferences.javaScriptEnabled = true;
        let webView = WKWebView.init(frame: CGRect.zero, configuration: configuration)
        webView.backgroundColor = UIColor.white
        webView.uiDelegate = self;
        webView.navigationDelegate = self;
        return webView
    }()
    lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.backgroundColor = UIColor.blue
        //        progressView.progressTintColor = UIColor.blue
        return progressView
    }()
    lazy var shareBtn: UIButton = {
        let shareBtn = UIButton()
        shareBtn.setImage(UIImage(named: "share"), for: .normal)
        shareBtn.isHidden = true
        return shareBtn
    }()
    lazy var backBtn: UIButton = {
        let backBtn = UIButton()
        backBtn.setImage(UIImage(named: "back"), for: .normal)
        backBtn.isHidden = true
        return backBtn
    }()
}
//MARK: - WKUIDelegate
extension HPHeather:WKUIDelegate,WKNavigationDelegate{
    
    // 页面加载完成之后调用
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.evaluateJavaScript("registerEnv('ios')", completionHandler: { (_, _) in
        })
    }
}
//MARK: - WKScriptMessageHandler
extension HPHeather:WKScriptMessageHandler{
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let json = JSON(parseJSON: message.body as! String).dictionary else { return  }
        messageForward(json: json)
    }
}
//MARK: - UI
extension HPHeather {
    func setUI()  {
        let navTitleDic = [NSAttributedString.Key.foregroundColor:UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1)];
        navigationController?.navigationBar.titleTextAttributes = navTitleDic;
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.shareBtn)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.backBtn)
        
        view.addSubview(progressView)
        view.addSubview(webView)
        
        progressView.snp.makeConstraints{
            $0.top.right.left.equalTo(0)
            $0.height.equalTo(1.5)
        }
        webView.snp.makeConstraints{
            $0.top.equalTo(progressView.snp.bottom)
            $0.bottom.right.left.equalTo(0)
        }
    }
    
}
//MARK: - subscribe
extension HPHeather {
    func subscribe() {
        let _ =  webView.rx.observe(URL.self, "URL").subscribe(onNext: {[weak self] (value) in
            guard let self = self else { return  }
            guard let url = value else { return  }
            guard let oldUrl = self.url else { return  }
            if url.absoluteString != oldUrl.absoluteString{
                self.url = url;
            }
            self.showBackIcon(url: url.absoluteString)
            self.showShareIcon(url: url.absoluteString)
        })
        let authRespNotificationName = Notification.Name(rawValue: "SendAuthRespCode")
        let wxPayRespNotificationName = Notification.Name(rawValue: "WXPaySuccess")
        let zfbPayRespNotificationName = Notification.Name(rawValue: "AlipayPay")
        
        _ = NotificationCenter.default.rx
            .notification(authRespNotificationName)
            .takeUntil(self.rx.deallocated)
            .subscribe(onNext: {[weak self] notification in
                guard let self = self else { return  }
                let userInfo = notification.userInfo as! [String: AnyObject]
                guard let code = userInfo["code"] as? String else { return  }
                guard let url = URL(string: "https://www.mabao75.com/auth/wechat?code=\(code)&platform=app") else { return  }
                guard let oldUrl = self.url else { return  }
                if url.absoluteString != oldUrl.absoluteString{
                    self.webView.load(URLRequest(url: url))
                }
            })
        _ = NotificationCenter.default.rx
            .notification(wxPayRespNotificationName)
            .takeUntil(self.rx.deallocated)
            .subscribe(onNext: {[weak self] notification in
                guard let self = self else { return  }
                guard let paySuccessUrl = self.paySuccessUrl else { return  }
                self.webView.load(URLRequest(url: paySuccessUrl))
            })
        _ = NotificationCenter.default.rx
            .notification(zfbPayRespNotificationName)
            .takeUntil(self.rx.deallocated)
            .subscribe(onNext: {[weak self] notification in
                guard let self = self else { return  }
                let userInfo = notification.userInfo as! [String: AnyObject]
                print(userInfo)
                
                guard let paySuccessUrl = self.paySuccessUrl else { return  }
                self.webView.load(URLRequest(url: paySuccessUrl))
            })
        _ =  webView.rx.observe(String.self, "title").subscribe(onNext: {[weak self] (value) in
            guard let self = self else { return  }
            guard let title = value else { return  }
            self.title = title
        })
        _ =  webView.rx.observe(NSNumber.self, "estimatedProgress").subscribe(onNext: {[weak self] (value) in
            guard let self = self else { return  }
            guard let estimatedProgress = value else { return  }
            if self.progressView.progress == 1 && estimatedProgress.floatValue != 1{
                self.progressView.isHidden = false;
            }
            self.progressView.progress = estimatedProgress.floatValue
            if estimatedProgress.floatValue == 1 {
                print(self.progressView)
                UIView.animate(withDuration: 0.25, delay: 0.3, options: .curveEaseIn, animations: {
                    self.progressView.transform = CGAffineTransform.init(scaleX: 1, y: 1.4)
                }, completion: { (finished) in
                    self.progressView.isHidden  = true
                })
            }
        })
        
        _ = backBtn.rx.tap.subscribe {[weak self] (_) in
            guard let self = self else { return  }
            self.goBack()
            
        }
        _ =  shareBtn.rx.tap.subscribe {[weak self] (_) in
            guard let self = self else { return  }
            self.webView.evaluateJavaScript("registerAppShareInfo()", completionHandler: { (_,_) in
            })
        }
    }
    func goBack()  {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    func showShareIcon(url:String)  {
        if url.contains("share") {
            shareBtn.isHidden = false
        }else{
            shareBtn.isHidden = true
        }
    }
    func showBackIcon(url:String)  {
        if  (url == homeUrl || url == indexUrl || url == categoryUrl) {
            backBtn.isHidden = true
        }else{
            backBtn.isHidden = false
        }
    }
    
}
//MARK: - pay
extension HPHeather{
    func wxPay(_ json:[String:JSON]) {
        guard let config = json["config"]?.dictionary else { return }
        let pay = PayReq()
        print(config)
        pay.partnerId = config["partnerid"]?.stringValue
        pay.prepayId = config["prepayid"]?.stringValue
        pay.sign = config["sign"]?.stringValue
        pay.nonceStr = config["noncestr"]?.stringValue
        if let  timeStamp = config["timestamp"]?.uInt32{
            pay.timeStamp = timeStamp
        }
        if let package = config["package"]?.string{
            pay.package = package
        }
        if let paySuccessUrl = json["return_url"]?.string{
            self.paySuccessUrl = URL(string: paySuccessUrl)
        }
        WXApi.send(pay)
    }
    func zfpPay(_ json:[String:JSON])  {
        guard let orderString = json["config"]?.string else { return }
        if let paySuccessUrl = json["return_url"]?.string{
            self.paySuccessUrl = URL(string: paySuccessUrl)
        }
        AlipaySDK.defaultService()?.payOrder(orderString, fromScheme: "HPHeatherAPP", callback: { (value) in
            print(value)
            
        })
    }
}
//MARK: - share or login
extension HPHeather{
    func share(_ json:[String:JSON])  {
        guard let share_title = json["share_title"]?.string else { return }
        let shareParames = NSMutableDictionary()
        shareParames.ssdkSetupShareParams(byText:json["share_desc"]?.stringValue , images: [json["share_logo"]?.stringValue], url:json["share_link"]?.url , title: share_title, type: .webPage)
        ShareSDK.share(.subTypeWechatSession, parameters: shareParames) { (_, _, _, _) in
        }
    }
    func wechatLogin() {
        let req = SendAuthReq()
        req.scope = "snsapi_userinfo"
        req.state = "HPHeather"
        if  WXApi.send(req) {
            print("success")
        }else{
            print("error")
        }
    }
}
//MARK: - HHMSDK
extension HPHeather{
    func HHMSDKLogin(_ json:[String:JSON])  {
        guard let uuid = json["uuid"]?.intValue else { return }
        HHMSDK.default.logout()
        HHMSDK.default.login(uuid: uuid) { (error) in
            if let aError = error {
                print("登录错误: " + aError.localizedDescription)
            }else{
                print("登录")
            }
        }
    }
    func getMedicList(_ json:[String:JSON])  {
        guard let userToken = json["userToken"]?.string else { return  }
        guard let url = URL(string: HHMSDK.default.getMedicList(userToken: userToken)) else { return  }
        self.webView.load(URLRequest(url: url))
    }
}
//MARK: - WKScriptMessageHandler message.body
extension HPHeather{
    func messageForward(json:[String:JSON])  {
        guard let type = json["type"]?.string else {
            share(json)
            return
        }
        switch type {
        case "wx":
            wxPay(json)
        case "zfb":
            zfpPay(json)
        case "login":
            HHMSDKLogin(json)
        case "adult":
            HHMSDK.default.startCall(.adult)
        case "children":
            HHMSDK.default.startCall(.child)
        case "wechat":
            wechatLogin()
        case "case":
            getMedicList(json)
        default:
            print("--")
        }
    }
    
}
//MARK: - WKUserContentController 注册和销毁 js方法
extension HPHeather{
    func removeScriptMessageHandler()  {
        self.webView.configuration.userContentController.removeScriptMessageHandler(forName: "THIRD_LOGIN_INTERFACE")
        self.webView.configuration.userContentController.removeScriptMessageHandler(forName: "APP_PAY_INTERFACE")
        self.webView.configuration.userContentController.removeScriptMessageHandler(forName: "APP_SHARE_INTERFACE")
        self.webView.configuration.userContentController.removeScriptMessageHandler(forName: "HH_SDK_INTERFACE")
    }
    func addScriptMessageHandler()  {
        self.webView.configuration.userContentController.add(self , name: "THIRD_LOGIN_INTERFACE")
        self.webView.configuration.userContentController.add(self , name: "APP_PAY_INTERFACE")
        self.webView.configuration.userContentController.add(self , name: "APP_SHARE_INTERFACE")
        self.webView.configuration.userContentController.add(self , name: "HH_SDK_INTERFACE")
    }
}

