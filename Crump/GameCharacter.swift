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
    unowned var sprite: SKSpriteNode
    var direction: Direction = .None
    var wantToGo: Direction = .None  //where trying to go after next decision point
    unowned let dpkw: DecisionPointKnowledgeWorker
    var speed: CGFloat = CGFloat(0.01)  // seconds per pixel
    let MOVE_KEY: String = "MoveActionKey"
    let ROTATE_KEY: String = "RotateActionKey"
    
    init(sprite: SKSpriteNode, knowledgeWorker: DecisionPointKnowledgeWorker, categoryBitMask: UInt32, contactTestBitMask: UInt32) {
        self.sprite = sprite
        self.dpkw = knowledgeWorker
        self.sprite.physicsBody = SKPhysicsBody(rectangleOf: self.sprite.size)
        self.sprite.physicsBody?.isDynamic = true
        self.sprite.physicsBody?.categoryBitMask = categoryBitMask
        self.sprite.physicsBody?.contactTestBitMask = contactTestBitMask
        self.sprite.physicsBody?.collisionBitMask = 0
    }
    
    fileprivate func calcDuration (_ to:CGPoint) -> TimeInterval {
        return TimeInterval(distance(sprite.position, p2: to) * speed)
    }
    
    //hook for subclasses when dead end reached
    func reachedDeadEnd() {
        return
    }
    
    func move() {
        //if off the board, put at the beginning of the other side of it
        let tempDirection: Direction = wantToGo
        //print("sprite.position: \(sprite.position)")
        if sprite.position.x < (-sprite.frame.size.width / 3) {
            print("too far left")
            sprite.position.x = dpkw.tileSetFrame.width + sprite.frame.size.width / 3
            wantToGo = .Left
        } else if sprite.position.x > (dpkw.tileSetFrame.width + sprite.frame.size.width / 3) {
            print("too far right")
            sprite.position.x = -sprite.frame.size.width / 3
            //println("\(sprite.position)")
            wantToGo = .Right
        } else if sprite.position.y < (-sprite.frame.size.height / 3) {
            print("too far down")
            sprite.position.y = dpkw.tileSetFrame.height + sprite.frame.size.height / 3
            wantToGo = .Down
        } else if sprite.position.y > (dpkw.tileSetFrame.height + sprite.frame.size.height / 3) {
            print("too far up")
            sprite.position.y = -sprite.frame.size.height / 3
            wantToGo = .Up
        }
        
        //now we're going in the direction we want to
        if let canI = dpkw.findDecisionPoint(sprite.position, inDirection: wantToGo) {
            //print("Found decision point: \(canI)")
            //sprite.removeAllActions()
            sprite.removeAction(forKey: ROTATE_KEY)
            sprite.removeAction(forKey: MOVE_KEY)
            direction = wantToGo;
            //rotate to be the right direction
            sprite.run(SKAction.rotate(toAngle: direction.radians, duration: 0.1, shortestUnitArc: true), withKey: ROTATE_KEY)
            sprite.run(SKAction.sequence([SKAction.move(to: canI, duration: calcDuration(canI)), SKAction.run({
                self.move()
            })]), withKey: MOVE_KEY)
        } else if let canI = dpkw.findDecisionPoint(sprite.position, inDirection: direction) {
            //println("Found decision point: \(canI)")
            //sprite.removeAllActions()
            sprite.removeAction(forKey: ROTATE_KEY)
            sprite.removeAction(forKey: MOVE_KEY)
            //rotate to be the right direction
            sprite.run(SKAction.rotate(toAngle: direction.radians, duration: 0.1, shortestUnitArc: true), withKey: ROTATE_KEY)
            sprite.run(SKAction.sequence([SKAction.move(to: canI, duration: calcDuration(canI)), SKAction.run({
                self.move()
                })]), withKey: MOVE_KEY)
        } else {
            direction = .None
            reachedDeadEnd()
        }
        
        wantToGo = tempDirection
    }
}
