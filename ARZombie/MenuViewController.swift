//
//  MenuViewController.swift
//  ARBowling
//
//  Created by Tri Dang on 12/9/19.
//  Copyright © 2019 Tri Dang. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    var highscore = 0
    
    @IBOutlet weak var highscoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // is there an existing highscore?
        if UserDefaults.standard.object(forKey: "highscore") == nil {
            highscore = 0
            highscoreLabel.text = String(highscore)
            
        }
        highscore = UserDefaults.standard.integer(forKey: "highscore")
        highscoreLabel.text = String(highscore)
    }
    
    @IBAction func playBtn(_ sender: UIButton) {
        performSegue(withIdentifier: "MenuToGame", sender: self)
    }
    
    // custom unwind
    @IBAction func unwindGame(segue:UIStoryboardSegue) {
        if let source = segue.source as? GameViewController {
            if source.currentScore > highscore {
                updateHighscore(score: source.currentScore)
            }
        }
    }
    
    func updateHighscore(score:Int) {
        highscore = score
        highscoreLabel.text = String(score)
        UserDefaults.standard.set(score, forKey: "highscore")
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
