/*
GameScene.swift - Main level loading/general game management routines
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

protocol DecisionPointKnowledgeWorker {
    var frame: CGRect { get }
    var playersLocation: [CGPoint] { get }  //location of player(s) on screen
    func findDecisionPoint(fromLocation: CGPoint, inDirection: Direction) -> CGPoint?
}

enum Direction : String {
    case Left = "Left", Right = "Right", Up = "Up", Down = "Down", None = "None"
    var opposite: Direction {
        switch(self) {
        case (.Left): return .Right
        case (.Right): return .Left
        case (.Up): return .Down
        case (.Down): return .Up
        default: return .None
        }
    }
    var radians: CGFloat {
        switch(self) {
        case (.Left): return CGFloat(M_PI / 2)
        case (.Right): return CGFloat(M_PI * (3 / 2))
        case (.Up): return 0
        case (.Down): return CGFloat(M_PI)
        default: return 0
            }
    }
}

class GameScene: SKScene, DecisionPointKnowledgeWorker {
    var tiledMap: JSTileMap
    var level: Int
    var players: [Player] = []
    var enemies: [Enemy] = []

    //location of all of the players
    var playersLocation: [CGPoint] {
        return players.map{ (var p) -> CGPoint in
            return p.sprite.position
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(levelToLoad: Int, numPlayers: Int) {
        level = levelToLoad
        tiledMap = JSTileMap(named: "level\(level).tmx")
        //let playerLocation = tiledMap.groupNamed("Stuff").objectNamed("Enemy1")
        //println(playerLocation["type"]!)
        
        super.init(size: CGSizeMake(tiledMap.mapSize.width * tiledMap.tileSize.width, tiledMap.mapSize.height * tiledMap.tileSize.height))
        
        //preliminary code for future multiplayer support
        for i in 1 ... numPlayers {
            var playerSprite: SKSpriteNode = tiledMap.childNodeWithName("Player\(i)") as SKSpriteNode
            var p = Player(sprite: playerSprite, knowledgeWorker: self, playerNumber: i)
            players.append(p)
        }
        
        //Swift doesn't have good reflection/introspection yet, so we can't easily create a new class from a String name
        //Instead we resort to this ugly switch
        for dict in tiledMap.groupNamed("Enemies").objects {
            switch(dict["type"]! as String) {
            case "EightBallz":
                let name: String = dict["name"]! as String
                var enemySprite: SKSpriteNode = tiledMap.childNodeWithName(name) as SKSpriteNode
                var e = EightBall(sprite: enemySprite, knowledgeWorker: self)
                enemies.append(e)
                e.move()
            default:
                break
            }
        }
        
        anchorPoint = CGPointMake(0.5, 0.5)
        let mapBounds = tiledMap.calculateAccumulatedFrame()
        tiledMap.position = CGPointMake(-mapBounds.size.width/2.0, -mapBounds.size.height/2.0);
        //println(tiledMap.)
        addChild(tiledMap)
    }
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        /*let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)*/
    }
    
    func pause() {
        if (!paused) {
            let myLabel = SKLabelNode(fontNamed:"Chalkduster")
            myLabel.text = "Paused"
            myLabel.name = "Paused"
            myLabel.fontSize = 65
            myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
            addChild(myLabel)
        } else {
            let myLabel = childNodeWithName("Paused")
            myLabel.removeFromParent()
        }
        paused = !paused
    }
    
    //find the next place where moving in the current direction
    func findDecisionPoint(fromLocation: CGPoint, inDirection: Direction) -> CGPoint? {
        let wallLayer: TMXLayer = tiledMap.layerNamed("Walls")
        switch (inDirection) {
        case .Right:
            var tempX: CGFloat
            if (fromLocation.x < 0) {  //deal with negative values
                tempX = tiledMap.tileSize.width / 2
            } else {
                tempX = round(fromLocation.x) + (tiledMap.tileSize.width - (round(fromLocation.x) % tiledMap.tileSize.width)) + (tiledMap.tileSize.width / 2)
            }
            if (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y)) != nil) {
                println("something here at \(tempX), \(fromLocation.y)!")
                return nil
            }
            for var i:CGFloat = 0; i <= tiledMap.mapSize.width; i++ {
                if (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y - tiledMap.tileSize.height)) == nil) || (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y + tiledMap.tileSize.height)) == nil) || (wallLayer.tileAt(CGPoint(x: tempX + tiledMap.tileSize.width, y: fromLocation.y)) != nil) {
                    return CGPoint(x: tempX, y: fromLocation.y)
                }
                tempX += tiledMap.tileSize.width
            }
            return nil
        case .Left:
            var tempX = round(fromLocation.x) - (round(fromLocation.x) % tiledMap.tileSize.width) - (tiledMap.tileSize.width / 2)
            if (tempX == fromLocation.x) {
                tempX -= tiledMap.tileSize.width
            }
            if (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y)) != nil) {
                return nil
            }
            for var i:CGFloat = 0; i <= tiledMap.mapSize.width; i++ {
                if (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y - tiledMap.tileSize.height)) == nil) || (wallLayer.tileAt(CGPoint(x: tempX, y: fromLocation.y + tiledMap.tileSize.height)) == nil) || (wallLayer.tileAt(CGPoint(x: tempX - tiledMap.tileSize.width, y: fromLocation.y)) != nil) {
                    return CGPoint(x: tempX, y: fromLocation.y)
                }
                tempX -= tiledMap.tileSize.width
            }
            return nil
        case .Up:
            var tempY: CGFloat
            if (fromLocation.y < 0) {  //deal with negative values
                tempY = tiledMap.tileSize.height / 2
            } else {
                tempY = round(fromLocation.y) + (tiledMap.tileSize.height - (round(fromLocation.y) % tiledMap.tileSize.height)) + (tiledMap.tileSize.height / 2)
            }
            if (wallLayer.tileAt(CGPoint(x: fromLocation.x, y: tempY)) != nil) {
                return nil
            }
            for var i:CGFloat = 0; i <= tiledMap.mapSize.height; i++ {
                if (wallLayer.tileAt(CGPoint(x: fromLocation.x - tiledMap.tileSize.width, y: tempY)) == nil) ||
                    (wallLayer.tileAt(CGPoint(x: fromLocation.x + tiledMap.tileSize.width, y: tempY )) == nil) ||
                    (wallLayer.tileAt(CGPoint(x: fromLocation.x, y: tempY + tiledMap.tileSize.height)) != nil) {
                    return CGPoint(x: fromLocation.x, y: tempY)
                }
                tempY += tiledMap.tileSize.height
            }
            return nil
        case .Down:
            var tempY = round(fromLocation.y) - (round(fromLocation.y) % tiledMap.tileSize.height) - (tiledMap.tileSize.height / 2)
            if (tempY == fromLocation.y) {
                
                tempY -= tiledMap.tileSize.height
            }
            println("Testing wallLayer at \(tempY)");
            if (wallLayer.tileAt(CGPoint(x: fromLocation.x, y: tempY)) != nil) {
                println("something here at \(fromLocation.x), \(tempY))!")
                return nil
            }
            for var i:CGFloat = 0; i <= tiledMap.mapSize.height; i++ {
                println("Testing \(tempY)");
                if (wallLayer.tileAt(CGPoint(x: fromLocation.x - tiledMap.tileSize.width, y: tempY)) == nil) ||
                    (wallLayer.tileAt(CGPoint(x: fromLocation.x + tiledMap.tileSize.width, y: tempY )) == nil) ||
                    (wallLayer.tileAt(CGPoint(x: fromLocation.x, y: tempY - tiledMap.tileSize.height)) != nil) {
                    return CGPoint(x: fromLocation.x, y: tempY)
                }
                tempY -= tiledMap.tileSize.height
            }
            return nil
        default:  //if .None
            return nil
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        pause()
    }
    
    override func keyDown(theEvent: NSEvent) {
        let temp: String = theEvent.characters
        for letter in temp {
            switch (letter) {
            case "p":
                pause()
            default:
                for player in players {
                    if let tempDirection = player.keyBindings["\(letter)"] {
                        player.wantToGo = tempDirection
                        if (player.direction == .None || player.wantToGo == player.direction.opposite) {  //if player's not moving, move him
                            player.move()
                        }
                    }
                }
            }
        }
        
        //check if None currently then move
        
        //check if trying to go opposite direction, then do so immediately
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
