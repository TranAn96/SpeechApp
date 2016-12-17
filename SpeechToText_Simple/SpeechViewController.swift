//
//  SpeechViewController.swift
//  SpeechToText_Simple
//
//  Created by Trần An on 12/17/16.
//  Copyright © 2016 Trần An. All rights reserved.
//

import UIKit
import Speech

class SpeechViewController: UIViewController,SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var btnTouch: UIButton!
    @IBOutlet weak var lblText: UILabel!
    
    var numberTouch = 0
    
    private let arr = ["TOUCH HERE AND SAY SOMETHING","SPEECH AGAIN"]
    
    private let speechTest = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private var bufferRecogRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        btnTouch.isEnabled = false
        
        speechTest.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            
            var isButtonEnabled = false
            
            switch status {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("DON'T ALOW ACESS")
                
            case .restricted:
                isButtonEnabled = false
                print("DON'T FIND DEVICE ")
                
            case .notDetermined:
                isButtonEnabled = false
                print("DON'T SUCESSFUL")
            }
            
            OperationQueue.main.addOperation() {
                self.btnTouch.isEnabled = isButtonEnabled
            }
        }
        
    }


    @IBAction func touchSpeech(_ sender: Any) {
                if audioEngine.isRunning {
            audioEngine.stop()
            bufferRecogRequest?.endAudio()
            btnTouch.isEnabled = false
            btnTouch.setTitle("TYPING ....", for: .normal)
        } else {
            startSpeech()
            btnTouch.setTitle("SPEECH AGAIN ", for: .normal)
        }
        numberTouch += 1
        btnTouch.setTitle(arr[numberTouch % 2], for: .normal)
    }
    func startSpeech() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSpeech = AVAudioSession.sharedInstance()
        do {
            try audioSpeech.setCategory(AVAudioSessionCategoryRecord)
            try audioSpeech.setMode(AVAudioSessionModeMeasurement)
            try audioSpeech.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("TRAN TUAN AN EXEPTION")
        }
        
        bufferRecogRequest = SFSpeechAudioBufferRecognitionRequest()  
        
        guard let input = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = bufferRecogRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechTest.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.lblText.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                input.removeTap(onBus: 0)
                self.bufferRecogRequest = nil
                self.recognitionTask = nil
                self.btnTouch.isEnabled = true
            }
        })
        
        let recordingFormat = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.bufferRecogRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("EXEPTION NOT FOUND !!!!")
        }
        
        lblText.text = "SAY SOMETHING WITH ME !!!!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            btnTouch.isEnabled = true
        } else {
            btnTouch.isEnabled = false
        }
    }

}
