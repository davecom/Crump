//
//  Player.swift
//  Crump
//
//  Created by David Kopec on 7/21/14.
//  Copyright (c) 2014 Oak Snow Consulting. All rights reserved.
//

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
        let dx = sprite.position.x - to.x
        let dy = sprite.position.y - to.y
        return NSTimeInterval(sqrt(dx * dx + dy * dy) * speed)
    }
    
    func move() {
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