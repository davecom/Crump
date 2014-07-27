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

class Player {
    var sprite: SKSpriteNode
    var score: Int = 0
    var direction: Direction = .None
    var wantToGo: Direction = .None  //where trying to go after next decision point
    //var playerNumber: Int  //player 1, player 2, etc mostly for key binding
    var keyBindings: [String: Direction] = Dictionary<String, Direction>()
    let dpkw: DecisionPointKnowledgeWorker
    var speed: CGFloat = CGFloat(0.01)  // seconds per pixel
    
    init(sprite: SKSpriteNode, playerNumber: Int, knowledgeWorker: DecisionPointKnowledgeWorker) {
        self.sprite = sprite
        self.dpkw = knowledgeWorker
        //self.playerNumber = playerNumber
        if let tempKeyBindings = NSUserDefaults.standardUserDefaults().dictionaryForKey("player\(playerNumber)KeyBindings"){
            for (key, value) in tempKeyBindings {
                keyBindings[(key as String)] = Direction.fromRaw(value as String)
            }
        } else { //if we don't have keybindings set defaults
            if playerNumber == 1 {
                keyBindings = ["a": .Left, "w": .Up, "s": .Down, "d": .Right]
            } else {
                keyBindings = ["4": .Left, "8": .Up, "5": .Down, "6": .Right]
            }
        }
    }
    
    private func calcDuration (to:CGPoint) -> NSTimeInterval {
        return NSTimeInterval(distance(sprite.position, to) * speed)
    }
    
    func move() {
        //if off the board, put at the beginning of the other side of it
        if sprite.position.x < (-sprite.frame.size.width / 2 + 2) {
            sprite.position.x = dpkw.frame.width + sprite.frame.size.width / 2 - 3
        } else if sprite.position.x > (dpkw.frame.width + sprite.frame.size.width / 2 - 2) {
            sprite.position.x = -sprite.frame.size.width / 2 + 3
        }
        
        //now we're going in the direction we want to
        if let canI = dpkw.findDecisionPoint(sprite.position, inDirection: wantToGo) {
            println("Found decision point: \(canI)")
            sprite.removeAllActions()
            direction = wantToGo;
            //rotate to be the right direction
            sprite.runAction(SKAction.rotateToAngle(direction.radians, duration: 0.1, shortestUnitArc: true))
            sprite.runAction(SKAction.sequence([SKAction.moveTo(canI, duration: calcDuration(canI)), SKAction.runBlock({
                self.move()
            })]))
        } else if let canI = dpkw.findDecisionPoint(sprite.position, inDirection: direction) {
            println("Found decision point: \(canI)")
            sprite.removeAllActions()
            //rotate to be the right direction
            sprite.runAction(SKAction.rotateToAngle(direction.radians, duration: 0.1, shortestUnitArc: true))
            sprite.runAction(SKAction.sequence([SKAction.moveTo(canI, duration: calcDuration(canI)), SKAction.runBlock({
                self.move()
                })]))
        } else {
            direction = .None
        }
    }
}