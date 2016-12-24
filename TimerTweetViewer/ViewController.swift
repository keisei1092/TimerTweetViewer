//
//  ViewController.swift
//  TimerTweetViewer
//
//  Created by Keisei Saito on 2016/12/24.
//  Copyright © 2016 keisei_1092. All rights reserved.
//
//  参考にしたもの
//  http://t-higashi.com/twitter-api-one
//  http://qiita.com/kwst/items/2ca7937a67a4f8ff59cb
//  https://gist.github.com/SatoshiKawabata/c73542cb164d0abfe2a1
//  http://qiita.com/nnsnodnb/items/d85235bca74f58c71b3f
//  http://qiita.com/teradonburi/items/f196b58d51372f7a3aab
//

import UIKit
import Accounts
import Social

final class ViewController: UIViewController {

    var accountStore: ACAccountStore = ACAccountStore()
    var twitterAccount: ACAccount?
    var tweets: [Tweet] = []
    var count = 0
    var timer: Timer?

    @IBOutlet weak var tweetContentLabel: UILabel!
    @IBOutlet weak var userIconImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.displayTweet(_:)), userInfo: nil, repeats: true)

        // Do any additional setup after loading the view, typically from a nib.
        getAccounts { (accounts: [ACAccount]) -> Void in
            self.showAccountSelectSheet(accounts: accounts) // この中でgetTimeLine()もされてる
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func displayTweet(_ timer: Timer) {
        print("displayTweet()")
        guard count < tweets.count else {
            return
        }

        tweetContentLabel?.text = "" // erase previous
        tweetContentLabel?.text = tweets[count].text
        print(tweets[count])
        count += 1
    }

    func getAccounts(callback: @escaping ([ACAccount]) -> Void) { // 循環参照になってないかあとで見る
        let accountType: ACAccountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: accountType, options: nil) { (granted: Bool, error: Error?) -> Void in
            guard error == nil else {
                print("error! \(error)")
                return
            }
            guard granted else {
                print("error! Twitterアカウントの利用が許可されていません")
                return
            }

            let accounts = self.accountStore.accounts(with: accountType) as! [ACAccount]
            guard accounts.count != 0 else {
                print("error! 設定画面からアカウントを設定してください")
                return
            }
            print("アカウント取得完了")
            callback(accounts)
        }
    }

    private func showAccountSelectSheet(accounts: [ACAccount]) {
        let alert = UIAlertController(title: "Twitter", message: "Choose an account", preferredStyle: .actionSheet)

        for account in accounts {
            alert.addAction(UIAlertAction(title: account.username, style: .default, handler: { [weak self] (action) -> Void in
                if let unwrapSelf = self {
                    unwrapSelf.twitterAccount = account
                    unwrapSelf.getTimeline()
                }
            }))
        }

        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2, y: self.view.bounds.size.height / 2, width: 1.0, height: 1.0)
        alert.popoverPresentationController?.permittedArrowDirections = .down
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func getTimeline() {
        let url = URL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json?count=20")
        guard let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, url: url, parameters: nil) else {
            return
        }
        request.account = twitterAccount
        request.perform { (responseData, response, error) -> Void in
            if error != nil {
                print(error ?? "error in performing request :[")
            } else {
                do {
                    guard let responseData = responseData else {
                        return
                    }
                    let result = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments)
                    for tweet in result as! [AnyObject] { // errorsが返ってくることがある
                        guard let text = tweet["text"] as? String, let createdAt = tweet["created_at"] as? String else { // これmodel側でやるべきな感じ
                            print("failed to map tweet string from JSON")
                            return
                        }

                        let user = tweet["user"] as? [String: Any]
                        guard let userName = user?["name"] as? String, let userScreenName = user?["screen_name"] as? String, let userProfileImageURLHTTPS = user?["profile_image_url_https"] as? String else {
                            print("failed to map user string from JSON")
                            return
                        }

                        let tweetObject = Tweet(text: text, createdAt: createdAt, user: User(name: userName, screenName: userScreenName, profileImageURLHTTPS: userProfileImageURLHTTPS))
                        self.tweets.append(tweetObject)
                    }
                    self.timer!.fire() // I think this force unwrap is safe... :[
                }  catch let error as NSError {
                    print(error)
                }
            }
        }
    }

}
