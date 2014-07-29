/*
Game Character.swift - A base class that both the player class and AI classes will inherit from
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

class GameCharacter {
    var sprite: SKSpriteNode
    var direction: Direction = .None
    var wantToGo: Direction = .None  //where trying to go after next decision point
    let dpkw: DecisionPointKnowledgeWorker
    var speed: CGFloat = CGFloat(0.01)  // seconds per pixel
    
    init(sprite: SKSpriteNode, knowledgeWorker: DecisionPointKnowledgeWorker) {
        self.sprite = sprite
        self.dpkw = knowledgeWorker
    }
    
    private func calcDuration (to:CGPoint) -> NSTimeInterval {
        return NSTimeInterval(distance(sprite.position, to) * speed)
    }
    
    //hook for subclasses when dead end reached
    func reachedDeadEnd() {
        
    }
    
    func move() {
        //if off the board, put at the beginning of the other side of it
        var tempDirection: Direction = wantToGo
        if sprite.position.x < (-sprite.frame.size.width / 2 + 2) {
            sprite.position.x = dpkw.frame.width + sprite.frame.size.width / 2 - 3
            wantToGo = .Left
        } else if sprite.position.x > (dpkw.frame.width + sprite.frame.size.width / 2 - 2) {
            sprite.position.x = -sprite.frame.size.width / 2 + 3
            //println("\(sprite.position)")
            wantToGo = .Right
        } else if sprite.position.y < (-sprite.frame.size.height / 2 + 2) {
            sprite.position.y = dpkw.frame.height + sprite.frame.size.height / 2 - 3
            wantToGo = .Down
        } else if sprite.position.y > (dpkw.frame.height + sprite.frame.size.height / 2 - 2) {
            sprite.position.y = -sprite.frame.size.height / 2 + 3
            wantToGo = .Up
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
            reachedDeadEnd()
        }
        
        wantToGo = tempDirection
    }
}