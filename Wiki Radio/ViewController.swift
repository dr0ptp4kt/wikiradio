//
//  ViewController.swift
//  Wiki Radio
//
//  Created by dr0ptp4kt on 5/23/15.
//  Copyright (c) 2015 Adam Baso. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate {

    var randomMusic: AVAudioPlayer?
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        println("finished playing the current downloaded music")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }
    
    @IBAction func playButton(sender: AnyObject) {

        println("start the queuing files")
        
        let dispatchQueue =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(dispatchQueue, {[weak self] in
            let mainBundle = NSBundle.mainBundle()
            
            /* Find the location of our file to feed to the audio player */
            let filePath = mainBundle.pathForResource("sample", ofType:"mp3")
            
            if let path = filePath{
                let fileData = NSData(contentsOfFile: path)
                
                var error:NSError?
                
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
            
            })
        
    }

        

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

}

