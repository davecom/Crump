/*
Player.swift - Code related to player management (sprite movement, keyboard bindings, etc)
Crump
Copyright (C) 2014  David Kopec

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

import SpriteKit

class Player: GameCharacter {
    var crumpMode: Bool = false
    private var CRUMP_KEY = "CRUMP_KEY"
    var crumpTime: TimeInterval = 10
    var score: Int = 0
    var lives: Int = 3
    //var playerNumber: Int  //player 1, player 2, etc mostly for key binding
    var keyBindings: [String: Direction] = Dictionary<String, Direction>()
    
    init(sprite: SKSpriteNode, knowledgeWorker: DecisionPointKnowledgeWorker, playerNumber: Int) {
        //self.playerNumber = playerNumber
        if let tempKeyBindings = UserDefaults.standard.dictionary(forKey: "player\(playerNumber)KeyBindings"){
            for (key, value) in tempKeyBindings {
                keyBindings[(key )] = Direction(rawValue: value as! String)
            }
        } else { //if we don't have keybindings set defaults
            if playerNumber == 1 {
                keyBindings = ["a": .Left, "w": .Up, "s": .Down, "d": .Right]
            } else {
                keyBindings = ["4": .Left, "8": .Up, "5": .Down, "6": .Right]
            }
        }
        super.init(sprite: sprite, knowledgeWorker: knowledgeWorker, categoryBitMask: PhysicsCategory.Player, contactTestBitMask: PhysicsCategory.PlayerContacts)
    }
    
    func crump() {
        print("crump")
        crumpMode = true
        sprite.removeAction(forKey: CRUMP_KEY)
        sprite.run(SKAction.sequence([
            SKAction.group([SKAction.scale(by: 1.25, duration: 1),
                            SKAction.colorize(with: NSColor.red, colorBlendFactor: 0.5, duration: 1)]),
            SKAction.wait(forDuration: crumpTime),
            SKAction.group([SKAction.scale(to: 1.0, duration: 1),
                            SKAction.colorize(with: NSColor.red, colorBlendFactor: 0.0, duration: 1)]),
            SKAction.run { [weak self] in
                self?.crumpMode = false
            }
            ]), withKey: CRUMP_KEY)
    }

}
