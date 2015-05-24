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
    var paused = false;
    var urlSession: NSURLSession!
    var currentSong: NSData?
    var nextSong: NSData?
    var retrievedFirstSong = false
    var playedFirstSong = false
    
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
        self.notPlaying()
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
            self.play()
        case .RemoteControlNextTrack:
            self.playNext()
            // TODO: handle Play/Pause toggle for earbuds
            // TODO: handle next track as well (Control center and double tab earbud)
            // see https://stackoverflow.com/questions/20591156/is-there-a-public-way-to-force-mpnowplayinginfocenter-to-show-podcast-controls
        default:
            break
        }
    }
    
    @IBAction func playForward(sender: AnyObject) {
        self.playNext()
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
        
        let url = NSURL(string: "https://upload.wikimedia.org/wikipedia/commons/d/d4/Zaip.wav")
        let task = self.urlSession.dataTaskWithURL(url!, completionHandler: {[weak self] (data: NSData!,
            response: NSURLResponse!, error: NSError!) in
            /* We got our data here */
            self!.nextSong = data
            println("Done")
            self!.urlSession.finishTasksAndInvalidate() })
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
    
    // defined for runtime safety
    func dummyPlayback() {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

}

