//
//  TrackingView.swift
//  DayOfDie
//
//  Created by Adam Berard on 9/11/21.
//

import Foundation
import UIKit

class TrackingViewController: UIViewController {
    
    @IBOutlet var trackerComponents : [TrackerComponent] = [] {
        didSet {
            trackerComponents.sort { $0.tag < $1.tag }
        }
    }
    @IBOutlet weak var scoreboard: PlayersTableScoreView!
    @IBOutlet weak var saveButton: UIButton!
    
    var players : [Player] = []
    
    var currentlyPickedPoints : Int = 0
    
    var teamOneScore : Int = 0 {
        didSet {
            scoreboard.teamOneScore = teamOneScore
            checkGameOver()
        }
    }
    var awayTeamScore : Int = 0 {
        didSet {
            scoreboard.awayTeamScore = awayTeamScore
            checkGameOver()
        }
    }
    
    var timeStarted : Date = Date()
//    var returnedGame : Game?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.isEnabled = false
        scoreboard.players = players
        
        for i in 0...3 {
            trackerComponents[i].mainTrackingViewController = self
            trackerComponents[i].player = players[i]
            trackerComponents[i].playerNumber = i
        }
    }
    
    // This is the function that everything calls when they update points
    func pointsDidChange() {
        // Just gotta update the player score labels and the team score labels
        teamOneScore = trackerComponents[0].numPoints + trackerComponents[1].numPoints
        awayTeamScore = trackerComponents[2].numPoints + trackerComponents[3].numPoints
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        checkGameOver()
    }
    
    private func checkGameOver(){
        let playToScore : Int = 11
        let winBy : Int = 2
        
        if abs(scoreboard.teamOneScore - scoreboard.awayTeamScore) < winBy {
            saveButton.isEnabled = false
        }
        else if max(scoreboard.teamOneScore, scoreboard.awayTeamScore) < playToScore {
            saveButton.isEnabled = false
        }
        else{
            saveButton.isEnabled = true
        }
    }
    
    func getPointsForParameters() -> [[String: String]] {
        var points : Array<Dictionary<String, String>> = []
        for trackerComponent in trackerComponents{
            for point in trackerComponent.points{
                let tempDict : [String : String] = ["type": point.typeOfPoint.rawValue, "scorer" : point.scorer.uuid]
                points.append(tempDict)
            }
        }
        return points
    }
    
    func getGameParameters() -> [String: Any] {
        var parameters : [String: Any] = [
            "playerOne": players[0].uuid,
            "playerTwo": players[1].uuid,
            "playerThree": players[2].uuid,
            "playerFour": players[3].uuid,
            "home_team_score": scoreboard.teamOneScore,
            "away_team_score": scoreboard.awayTeamScore,
            "confirmed": false,
            "points": getPointsForParameters()
        ]
        
//        let df = DateFormatter()
//        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let df = ISO8601DateFormatter()
        parameters["time_started"] = df.string(from: timeStarted)
        parameters["time_ended"] = df.string(from: Date())
        
        return parameters
    }
    
    @IBAction func saveGameButtonPressed(_ sender: Any) {
        let parameters = getGameParameters()
        
        APICalls.sendGame(parameters: parameters) { status, returnData in
            if status{
                let tempGame = returnData as? Game
                GameSet.updateAllGames(gameList: [tempGame!])
                let referencedGame = GameSet.getGame(inGame: tempGame!)
                self.updatePlayerAndTeamStats(game: referencedGame)
                
                self.resetEverything()
                
                self.performSegue(withIdentifier: "toGameAfterSave", sender: self)
            }
            else{
                let errors : [String] = returnData as! [String]
                // Alert Stuff
                let alert = UIAlertController(title: "Connection Error", message: errors.first, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cool", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    func updatePlayerAndTeamStats(game: Game) {
        if self.scoreboard.teamOneScore > self.scoreboard.awayTeamScore{
            game.homeTeam.wins += 1
            game.awayTeam.losses += 1
            game.homeTeam.teamCaptain.wins += 1
            game.homeTeam.teammate.wins += 1
            game.awayTeam.teamCaptain.losses += 1
            game.awayTeam.teammate.losses += 1
        }
        else{
            game.homeTeam.losses += 1
            game.awayTeam.wins += 1
            game.homeTeam.teamCaptain.losses += 1
            game.homeTeam.teammate.losses += 1
            game.awayTeam.teamCaptain.wins += 1
            game.awayTeam.teammate.wins += 1
        }
    }
    
    func resetEverything() -> Void {
        for pointTracker in trackerComponents{
            pointTracker.points = []
        }
    }
    
    //MARK: Segue Function
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if let identifier = segue.identifier {
            if identifier == "toPlayerPoints" {
                guard let viewController = segue.destination as? PlayerPointsTableViewController else {
                 fatalError("Unexpected destination: \(segue.destination)")}
                viewController.points = (trackerComponents)[currentlyPickedPoints].points
                viewController.mainTrackingViewController = self
            }
            else if identifier == "toGameAfterSave" {
                guard let viewController = segue.destination as? GameTableViewController else {
                 fatalError("Unexpected destination: \(segue.destination)")}
                viewController.needToGoToLastGame = true
            }
        }
    }
}
