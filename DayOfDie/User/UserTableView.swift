//
//  AddUserTableViewController.swift
//  DayOfDie
//
//  Created by Adam Berard on 5/3/21.
//

import UIKit

class UserTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    
    var friends : [Friend] = []
    var parentView : AddFriendViewController?
    
    override func reloadData() {
        loadData()
        super.reloadData()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loadData()
    }
    
    func loadData() {
        // Loading all users here
        APICalls.getUsers {status, returnData in
            if status{
                // Check if everything is done if so move on
                User.allUsers = returnData as! [User]
            }
            else{
                //Handle if things go wrong
                let errors : [String] = returnData as! [String]
                print(errors)
            }
        }
        
        var users = User.allUsers
        friends = []
        
        // Removing current user's username and also filtering search stuff
        users.removeAll(where: {
            !$0.username.starts(with: parentView?.searchBar.text ?? "") ||
                $0.username == ThisUser.user.username
        })

        // Taking out people I have as active, pending, or waiting
        
        users.removeAll(where: {
            for friend in Friend.allFriends{
                if friend.status != .NOTHING && $0.username == friend.getOtherUser().username{
                    return true
                }
            }
            return false
        })
        
        // Creating friends
        for user in users{
            friends.append(Friend.findOrCreateFriend(teamCaptain: ThisUser.user, teammate: user))
        }
    }
    
    // MARK: Table View Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "addFriendTableCell", for: indexPath) as? AddFriendTableViewCell  else {
            fatalError("The dequeued cell is not an instance of AddFriendTableViewCell.")
        }
        
        cell.friend = friends[indexPath.row]
        cell.parentTableView = self
        
        return cell
    }

}