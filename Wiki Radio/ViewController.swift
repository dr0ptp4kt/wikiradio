//
//  ViewController.swift
//  Wiki Radio
//
//  Created by dr0ptp4kt on 5/23/15.
//  Copyright (c) 2015 Adam Baso. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer



class ViewController: UIViewController, AVAudioPlayerDelegate, NSURLSessionDelegate {

    @IBOutlet weak var playButton: UIButton!
    var player: AVAudioPlayer?
    var audioSession: AVAudioSession?
    var interruptedOnPlayback = false
    var playing = false
    var paused = false
    var urlSession: NSURLSession!
    var currentSong: NSData?
    var nextSong: NSData?
    var retrievedFirstSong = false
    var playedFirstSong = false
    var categoriesArray: NSArray?
    var tracks: [String] = []
    var audioURLs : [String] = []
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UIApplication.sharedApplication().statusBarHidden = true
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        // the default is 60, but we can be more aggressive later if we want
        // configuration.timeoutIntervalForRequest = 15.0
        urlSession = NSURLSession(configuration: configuration, delegate: self,
        delegateQueue: nil)
    }
    
    func notPlaying() {
        self.playing = false
        self.playButton.setTitle(">", forState: UIControlState.Normal)
        self.playButton.setTitle(">", forState: UIControlState.Highlighted)
    }
    
    func updatePlayingButton() {
        self.playButton.setTitle("| |", forState: UIControlState.Normal)
        self.playButton.setTitle("| |", forState: UIControlState.Highlighted)
    }
    
    func play() {
        self.playing = true
        self.paused = false
        self.player!.play()
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        println("good music! finished playing the current downloaded music")
        self.updatePlayingButton()
        self.playNext()
    }
    
    func audioPlayerBeginInterruption(player: AVAudioPlayer!) {
        println("interrupting")
        if (self.playing) {
            println("interrupted while playing")
            self.playing = false
            self.interruptedOnPlayback = true
        }
    }
    
    func audioPlayerEndInterruption(player: AVAudioPlayer!) {
        println("interruption over")
        if (self.interruptedOnPlayback) {
            println("resume playing")
            self.player!.prepareToPlay()
            self.interruptedOnPlayback = false
            self.playing = self.player!.play()
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        retrieveCategories()
    }
    
    func playNext() {
        if (self.playedFirstSong) {
            self.currentSong = self.nextSong
        } else {
            self.playedFirstSong = true
        }
        self.retrieveNextSong()
        let dispatchQueue =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(dispatchQueue, {[weak self] in
            var error:NSError?
            // TODO: make forward button in UI actually immediately play
            // just like the Control Center does (assuming file is
            // downloaded)
            self!.player = AVAudioPlayer(data: self!.currentSong, error: &error)
            self!.player?.delegate = self!
            self!.player!.prepareToPlay()
            self!.play()
            })
    }

    @objc func routeChanged(notification: NSNotification){
        let reason = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! NSNumber?
        
        if reason == AVAudioSessionRouteChangeReason.CategoryChange.rawValue {
            // we control category changes, so ignore this
            return
        }
        
        if reason == AVAudioSessionRouteChangeReason.OldDeviceUnavailable.rawValue {
            self.player!.pause()
            self.paused = true
            self.notPlaying()
        }

    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent) {
        let type = event.subtype
        switch type {
        case .RemoteControlPause:
            self.player!.pause()
            self.paused = true
            self.notPlaying()
        case .RemoteControlPlay:
            self.player!.prepareToPlay()
            self.updatePlayingButton()
            self.play()
        case .RemoteControlNextTrack:
            self.updatePlayingButton()
            self.playNext()
            // TODO: handle Play/Pause toggle for earbuds
            // TODO: handle next track as well (Control center and double tab earbud)
            // see https://stackoverflow.com/questions/20591156/is-there-a-public-way-to-force-mpnowplayinginfocenter-to-show-podcast-controls
        default:
            break
        }
    }
    
    func initiateAudio() {
        if (self.audioSession == nil) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "routeChanged:", name: AVAudioSessionRouteChangeNotification, object: nil)
            self.audioSession = AVAudioSession.sharedInstance()
            var audioSessionError: NSError?
            self.audioSession?.setActive(true, error: &audioSessionError)
            var audioCatgeoryError: NSError?
            self.audioSession?.setCategory(AVAudioSessionCategoryPlayback, error: &audioCatgeoryError)
            
            // remoteControlReceivedWithEvent handles these events
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            
            
            

            // remoteControlReceivedWithEvent does the actual work via the other events
            // REMEMBER: the pause button only works on a physical device
            // The simulator Control Center will only show the Play button not toggling it
            // and will still show the forward button
            MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTarget(self, action: "dummyPlayback")
            MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.addTarget(self, action: "dummyPlayback")
        }
    }
    
    func retrieveNextSong() {
        if (!self.retrievedFirstSong) {
            let filePath = NSBundle.mainBundle().pathForResource("Abhogi", ofType:"wav")
            let fileURL = NSURL(fileURLWithPath: filePath!)
            self.currentSong = NSData(contentsOfURL: fileURL!)
            self.retrievedFirstSong = true
            return
        }
        
        // TODO ensure that files have indeed been populated
        // prior to trying to access them
        
        var url : NSURL?
        if (self.audioURLs.count == 0) {
            self.player!.pause()
            self.paused = true
            self.notPlaying()
            return
        }
        var u = self.audioURLs[0]
        println(u)
        self.audioURLs.removeAtIndex(0)
        url = NSURL(string: u)
        let task = self.urlSession.dataTaskWithURL(url!, completionHandler: {[weak self] (data: NSData!, response: NSURLResponse!, error: NSError!) in
            /* We got our data here */
            self!.nextSong = data
            println("Done")
            /* self!.urlSession.finishTasksAndInvalidate() */ })
        println("about to resume")
        task.resume()
        println("resumed")
    }
    
    
    @IBAction func playButton(sender: AnyObject) {
        if self.playing {
            self.player!.pause()
            self.paused = true
            self.notPlaying()
        } else if (self.paused) {
            self.player!.prepareToPlay()
            self.updatePlayingButton()
            self.play()
        } else {
            self.initiateAudio()
            self.retrieveNextSong()
            self.updatePlayingButton()
            playNext()
        }
    }
    
    @IBAction func playNextTrack(sender: AnyObject) {
        self.updatePlayingButton()
        self.playNext()
    }
    
    func retrieveCategories() {
        // https://commons.wikimedia.org/w/api.php?action=opensearch&search=Category:Audio%20files&limit=100
        
        let url = NSURL(string: "https://commons.wikimedia.org/w/api.php?action=opensearch&search=Category:Audio%20files&limit=100")
        let task = self.urlSession.dataTaskWithURL(url!, completionHandler: {[weak self] (data: NSData!, response: NSURLResponse!, error: NSError!) in
            var jsonError: NSError?
            let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonError)
            if jsonError == nil {
                let array = jsonObject as! NSArray
                if array.count > 1 {
                    self!.categoriesArray = array[1] as! NSArray
                    self!.retrieveFilePages()
                }
                
            }
            /* self!.urlSession.finishTasksAndInvalidate() */ })
        println("about to resume")
        task.resume()
    }
    
    func retrieveFilePages() {
        let divisor = 25
        // let divisor = 1
        let binSize = categoriesArray!.count / divisor
        let randomOffset = Int(arc4random_uniform(UInt32(binSize)))
        // let randomOffset = 0
        println(randomOffset)
        var categories : [String] = []
        for i in 0...divisor-1 {
            let randomCategoryPage = self.categoriesArray![i*binSize+randomOffset] as! String
            println(randomCategoryPage)
            let encodedRandomCategoryPage = randomCategoryPage.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
            
            // https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=Category:Audio%20files&cmtype=file&cmlimit=500
            let u = "https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=\(encodedRandomCategoryPage)&cmtype=file&cmlimit=500&format=json"
            // println(u)
            let url = NSURL(string: u)
            retrieveFilePage(url!)
            // println("still going")
        }
    }
    
    // FILE PAGE VERSION 2!
    /*
    func retrieveFilePages2() {
        let divisor = 5
        // let divisor = 1
        let binSize = categoriesArray!.count / divisor
        let randomOffset = Int(arc4random_uniform(UInt32(binSize)))
        // let randomOffset = 0
        println(randomOffset)
        var categories : [String] = []
        for i in 0...divisor-1 {
            let randomCategoryPage = self.categoriesArray![i*binSize+randomOffset] as! String
            println(randomCategoryPage)
            let encodedRandomCategoryPage = randomCategoryPage.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
            
            // https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=Category:Audio%20files&cmtype=file&cmlimit=500
            let u = "https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=\(encodedRandomCategoryPage)&cmtype=file&cmlimit=50&format=json"
            // println(u)
            let url = NSURL(string: u)
            retrieveFilePage(url!)
            // println("still going")
        }
    }
*/
    
    
    
    func retrieveFilePage(url: NSURL) {
        let task = self.urlSession.dataTaskWithURL(url, completionHandler: {[weak self] (json: NSData!, response: NSURLResponse!, error: NSError!) in
            
            // println(NSString(data: json, encoding: NSUTF8StringEncoding))
            var jsonError: NSError?
            let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(json, options: NSJSONReadingOptions.AllowFragments, error: &jsonError)
            if jsonError == nil {
                if jsonObject is NSDictionary {
                    let deserializedDictionary = jsonObject as! NSDictionary
                    let query = deserializedDictionary["query"] as! NSDictionary
                    if let categorymembers = query["categorymembers"] {
                        let categorymembersArray = categorymembers as! NSArray
                        //println(categorymembersArray)
                        var count = 0
                        for member in categorymembersArray {
                            /*
                            count++
                            if (count > 40) {
                                break;
                            }
                            if (count % 2 == 1) {
                                continue
                            }
                            */
                            let memberDict = member as! NSDictionary
                            let fileTitle: String = memberDict["title"] as! String
                            // println("file is \(fileTitle)")

                            if fileTitle.hasSuffix(".wav") {
                                if fileTitle.hasSuffix("Abhogi.wav") {
                                    continue
                                }
                                let encodedFileTitle = fileTitle.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
                                self!.tracks.append(encodedFileTitle)
                                self!.enqueueAudioURLs(encodedFileTitle)
                            }
                        }
                    }
                }
            }
            /* self!.urlSession.finishTasksAndInvalidate() */ })
        task.resume()
    }
    
    func enqueueAudioURLs(title: String) {
        println("enqueueing")
        
        
        let pipes: String = "canonicaltitle|size|mediatype|metadata|commonmetadata|extmetadata|bitdepth|derivatives".stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
        let u = "https://commons.wikimedia.org/w/api.php?action=query&titles=\(title)&prop=videoinfo&viprop=\(pipes)&format=json"
        let url = NSURL(string: u)
        
        // let audioURL: NSURL? = NSURL(string: u)
        /*
        if (audioURL == nil) {
        println("it's nil")
        }
        */
        // println(u)
        let task = self.urlSession.dataTaskWithURL(url!, completionHandler: {[weak self] (data: NSData!, response: NSURLResponse!, error: NSError!) in
            var jsonError: NSError?
            let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonError)
            if jsonError == nil {
                if jsonObject is NSDictionary {
                    let deserializedDictionary = jsonObject as! NSDictionary
                    //println(deserializedDictionary)
                    
                    
                    let query = deserializedDictionary["query"] as! NSDictionary
                    let pages = query["pages"] as! NSDictionary
                    let key = pages.allKeys[0] as! NSString
                    let theObject = pages[key] as! NSDictionary
                    let videoInfo = theObject["videoinfo"] as! NSArray
                    let video = videoInfo[0] as! NSDictionary
                    let derivatives = video["derivatives"] as! NSArray
                    let record = derivatives[0] as! NSDictionary
                    let src = record["src"] as! String
                    println(src)
                    self!.audioURLs.append(src)
                    
                    
                    
                    /*
                    println(query)
                    if let categorymembers = query["pages"] {
                    let categorymembersArray = categorymembers as! NSArray
                    //println(categorymembersArray)
                    for member in categorymembersArray {
                    let memberDict = member as! NSDictionary
                    let fileTitle: String = memberDict["title"] as! String
                    if fileTitle.hasSuffix(".wav") {
                    let encodedFileTitle = fileTitle.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
                    self!.tracks.append(encodedFileTitle)
                    */
                }
            }
            /* self!.urlSession.finishTasksAndInvalidate() */ })
        println("about to resume")
        task.resume()
        

    }
    
    
    // defined for runtime safety
    func dummyPlayback() {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

}

