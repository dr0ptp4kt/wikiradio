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
    var randomMusic: AVAudioPlayer?
    var player: AVAudioPlayer?
    var audioSession: AVAudioSession?
    var interruptedOnPlayback = false
    var playing = false
    var paused = false;
    var urlSession: NSURLSession!
    var nextSong: NSData?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 15.0
        urlSession = NSURLSession(configuration: configuration, delegate: self,
        delegateQueue: nil)
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        println("good music! finished playing the current downloaded music")
        self.playing = false
        self.playButton.setTitle(">", forState: UIControlState.Normal)
        self.playButton.setTitle(">", forState: UIControlState.Highlighted)
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
            self.playing = self.player!.play()
            self.interruptedOnPlayback = false
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().statusBarHidden = true
    }
    
    func playNext() {
        let dispatchQueue =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(dispatchQueue, {[weak self] in
        var error:NSError?
        self!.player = AVAudioPlayer(data: self!.nextSong, error: &error)
        self!.player?.delegate = self!
        self!.player!.prepareToPlay()
        self!.playing = true
        self!.player!.play()
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
            self.playing = false
            self.playButton.setTitle(">", forState: UIControlState.Normal)
            self.playButton.setTitle(">", forState: UIControlState.Highlighted)
        }

    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent) {
        let type = event.subtype
        switch type {
        case .RemoteControlPause:
            self.player!.pause()
            self.paused = true
            self.playing = false
            self.playButton.setTitle(">", forState: UIControlState.Normal)
            self.playButton.setTitle(">", forState: UIControlState.Highlighted)
        case .RemoteControlPlay:
            self.player!.prepareToPlay()
            self.paused = false
            self.playing = true
            self.player!.play()
            self.playButton.setTitle("| |", forState: UIControlState.Normal)
            self.playButton.setTitle("| |", forState: UIControlState.Highlighted)
        case .RemoteControlNextTrack:
            self.playNext()
            // TODO: handle Play/Pause toggle for earbuds
            // TODO: handle next track as well (Control center and double tab earbud)
            // see https://stackoverflow.com/questions/20591156/is-there-a-public-way-to-force-mpnowplayinginfocenter-to-show-podcast-controls
        default:
            break
        }
    }
    
    @IBAction func playButton(sender: AnyObject) {
        if self.playing {
            self.player!.pause()
            self.paused = true
            self.playing = false
            self.playButton.setTitle(">", forState: UIControlState.Normal)
            self.playButton.setTitle(">", forState: UIControlState.Highlighted)
            return
        } else if (self.paused) {
            self.player!.prepareToPlay()
            self.paused = false
            self.playing = true
            self.player!.play()
            self.playButton.setTitle("| |", forState: UIControlState.Normal)
            self.playButton.setTitle("| |", forState: UIControlState.Highlighted)
            return
        }
        
        self.playing = true;
        self.playButton.setTitle("| |", forState: UIControlState.Normal)
        self.playButton.setTitle("| |", forState: UIControlState.Highlighted)
        if (self.audioSession == nil) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "routeChanged:", name: AVAudioSessionRouteChangeNotification, object: nil)
            self.audioSession = AVAudioSession.sharedInstance()
            var audioSessionError: NSError?
            self.audioSession?.setActive(true, error: &audioSessionError)
            var audioCatgeoryError: NSError?
            self.audioSession?.setCategory(AVAudioSessionCategoryPlayback, error: &audioCatgeoryError)
            
            // remoteControlReceivedWithEvent handles these events
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            
            // this is just to forward indicate the buttons are supported,
            // remoteControlReceivedWithEvent does the actual work via the other events
            MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTarget(self, action: "dummyPlayback")
            MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.addTarget(self, action: "dummyPlayback")
            
            let url = NSURL(string: "https://upload.wikimedia.org/wikipedia/commons/0/0a/Arhin.wav")
            let task = self.urlSession.dataTaskWithURL(url!, completionHandler: {[weak self] (data: NSData!,
                response: NSURLResponse!, error: NSError!) in
                /* We got our data here */
                self!.nextSong = data
                println("Done")
                self!.urlSession.finishTasksAndInvalidate() })
            task.resume()
        }
        let dispatchQueue =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(dispatchQueue, {[weak self] in
            let mainBundle = NSBundle.mainBundle()
            
            /* Find the location of our file to feed to the audio player */
            let filePath = NSBundle.mainBundle().pathForResource("Abhogi", ofType:"wav")
            let fileURL = NSURL(fileURLWithPath: filePath!)
            var error:NSError?
            self!.player = AVAudioPlayer(contentsOfURL: fileURL!, error: &error)
            self!.player?.delegate = self!
            self!.player!.prepareToPlay()
            self!.playing = true
            self!.player!.play()

            /*
            if let path = filePath{
                let fileData = NSData(contentsOfFile: path)
                
                var error:NSError?
            
                self!.randomMusic = AVAudioPlayer(contentsOfURL: <#NSURL!#>, error: <#NSErrorPointer#>)
                
                /* Start the audio player */
                self!.randomMusic = AVAudioPlayer(data: fileData, error: &error)
                
                /* Did we get an instance of AVAudioPlayer? */
                if let player = self!.randomMusic{
                    /* Set the delegate and start playing */
                    player.delegate = self
                    if player.prepareToPlay() && player.play(){
                        /* Successfully started playing */
                    } else {
                        /* Failed to play */
                    }
                } else {
                    /* Failed to instantiate AVAudioPlayer */
                }
            }
*/
            
            })
        
    }
    
    // defined for runtime safety
    func dummyPlayback() {
    }

        

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

}

