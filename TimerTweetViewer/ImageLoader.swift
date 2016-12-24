//
//  ImageLoader.swift
//  TimerTweetViewer
//
//  Created by Keisei Saito on 2016/12/25.
//  Copyright © 2016 keisei_1092. All rights reserved.
//
//  参考
//  https://teamtreehouse.com/community/does-anyone-know-how-to-show-an-image-from-url-with-swift
//

import UIKit

final class ImageLoader {

    var cache = NSCache<NSString, UIImage>()

    class var shared: ImageLoader {
        struct Static {
            static let instance: ImageLoader = ImageLoader()
        }
        return Static.instance
    }

    func image(urlString: String, completionHandler: @escaping (UIImage?) -> ()) { // imageのみだけど元はimage, url: NSStringだった
        DispatchQueue.global(qos: .background).async {
            let data: Data? = self.cache.object(forKey: urlString as NSString) as? Data
            if let data = data {
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    completionHandler(image)
                }
                return
            }
            URLSession.shared.dataTask(with: URL(string: urlString)!, completionHandler: { (data, response, error) -> Void in
                if error != nil {
                    DispatchQueue.main.async {
                        completionHandler(nil)
                    }
                    return
                }
                if data != nil {
                    let image = UIImage(data: data!)
                    self.cache.setObject(image!, forKey: urlString as NSString)
                    DispatchQueue.main.async {
                        completionHandler(image)
                    }
                    return
                }
            }).resume()
        }
    }
}
