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
    var tileSetFrame: CGRect { get }
    var playersLocation: [CGPoint] { get }  //location of player(s) on screen
    func findDecisionPoint(_ fromLocation: CGPoint, inDirection: Direction) -> CGPoint?
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
        case (.Left): return CGFloat.pi / 2
        case (.Right): return CGFloat.pi * (3 / 2)
        case (.Up): return 0
        case (.Down): return CGFloat.pi
        default: return 0
            }
    }
}

struct PhysicsCategory {
    static let None : UInt32 = 0
    static let All : UInt32 = UInt32.max
    static let Enemy : UInt32 = 1
    static let Projectile: UInt32 = 2
    static let Player: UInt32 = 3
}

class GameScene: SKScene, DecisionPointKnowledgeWorker, SKPhysicsContactDelegate {
    var tiledMap: SKTileMapNode = SKTileMapNode()
    var level: Int = 1
    var players: [Player] = []
    var enemies: [Enemy] = []
    
    var tileSetFrame: CGRect {
        return tiledMap.frame
    }

    //location of all of the players
    var playersLocation: [CGPoint] {
        return players.map{ (p) -> CGPoint in
            return p.sprite.position
        }
    }
    
    // must override all designated initializers to use convenience initializer in super class (fileNamed: )
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(level: Int, numPlayers: Int) {
        self.init(fileNamed: "Level\(level)")!

        self.level = level
        self.tiledMap = self.childNode(withName: "Tile Map Node") as! SKTileMapNode
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        //print("frame: \(self.frame)")
        //print("tilemapframe: \(tiledMap.frame)")
        
        //preliminary code for future multiplayer support
        for i in 1 ... numPlayers {
            let playerSprite: SKSpriteNode = self.childNode(withName: "Player\(i)") as! SKSpriteNode
            let p = Player(sprite: playerSprite, knowledgeWorker: self, playerNumber: i)
            players.append(p)
        }
        
        for i in 0..<self.tiledMap.numberOfColumns {
            for j in 0..<self.tiledMap.numberOfRows {
                let sl: SKLabelNode = SKLabelNode(text: "\(i),\(j)")
                let pos = tiledMap.centerOfTile(atColumn: i, row: j)
                self.addChild(sl)
                sl.fontSize = 10.0
                sl.position = pos
            }
        }
        
        //Swift doesn't have good reflection/introspection yet, so we can't easily create a new class from a String name
        //Instead we resort to this ugly switch
        for child in self.children {
            if let name = child.name {
                switch (name) {
                case "EightBall":
                    let enemySprite: SKSpriteNode = self.childNode(withName: name) as! SKSpriteNode
                    let e = EightBall(sprite: enemySprite, knowledgeWorker: self)
                    enemies.append(e)
                    e.move()
                case "Sun":
                    let enemySprite: SKSpriteNode = self.childNode(withName: name) as! SKSpriteNode
                    let e = Sun(sprite: enemySprite, knowledgeWorker: self)
                    enemies.append(e)
                    e.move()
                default:
                    break
                }
            }
        }
    }
    
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        /*let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)*/
    }
    
    func pause() {
        if (!isPaused) {
            let myLabel = SKLabelNode(fontNamed:"Chalkduster")
            myLabel.text = "Paused"
            myLabel.name = "Paused"
            myLabel.fontSize = 65
            myLabel.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
            addChild(myLabel)
        } else {
            let myLabel = childNode(withName: "Paused")
            myLabel!.removeFromParent()
        }
        isPaused = !isPaused
    }
    
    //find the next place where moving in the current direction
    func findDecisionPoint(_ fromLocation: CGPoint, inDirection: Direction) -> CGPoint? {
        let fromCol = tiledMap.tileColumnIndex(fromPosition: fromLocation)
        let fromRow = tiledMap.tileRowIndex(fromPosition: fromLocation)
        //print("fromCol: \(fromCol)")
        //print("fromRow: \(fromRow)")
        //print("inDirection: \(inDirection)")
        switch (inDirection) {
        case .Right:
            if fromCol >= tiledMap.numberOfColumns && tiledMap.tileDefinition(atColumn: 0, row: fromRow) == nil {
                
                let center = self.tiledMap.centerOfTile(atColumn: fromCol, row: fromRow)
                let toPoint = CGPoint(x: center.x + tiledMap.tileSize.width, y: center.y)
                print("fromCol > rightside; sending to \(toPoint)")
                return toPoint
            }
            for col in (fromCol + 1 < tiledMap.numberOfColumns ? fromCol + 1 : fromCol)..<tiledMap.numberOfColumns {
                //print("row: \(row) def: \(tiledMap.tileDefinition(atColumn: fromCol, row: row))")
                if col == tiledMap.numberOfColumns - 1 && tiledMap.tileDefinition(atColumn: col, row: fromRow) == nil {
                    print("hit edge")
                    let center = self.tiledMap.centerOfTile(atColumn: col, row: fromRow)
                    return CGPoint(x: center.x + tiledMap.tileSize.width, y: center.y)
                }
                if tiledMap.tileDefinition(atColumn: col, row: fromRow) != nil {
                    print("already at wall")
                    return nil
                }
                if (tiledMap.tileDefinition(atColumn: col, row: fromRow - 1) == nil) || (tiledMap.tileDefinition(atColumn: col, row: fromRow + 1) == nil) || (tiledMap.tileDefinition(atColumn: col + 1, row: fromRow) != nil) {
                    return self.tiledMap.centerOfTile(atColumn: col, row: fromRow)
                }
            }
            return nil
        case .Left:
            if fromCol < 1 && tiledMap.tileDefinition(atColumn: tiledMap.numberOfColumns - 1, row: fromRow) == nil {
                
                let center = self.tiledMap.centerOfTile(atColumn: fromCol, row: fromRow)
                let toPoint = CGPoint(x: center.x - tiledMap.tileSize.width, y: center.y)
                print("fromCol < 0; sending to \(toPoint)")
                return toPoint
            }
            for col in (0..<(fromCol > 0 ? fromCol : 0)).reversed() {
                //print("row: \(row) def: \(tiledMap.tileDefinition(atColumn: fromCol, row: row))")
                if col == 0 && tiledMap.tileDefinition(atColumn: col, row: fromRow) == nil {
                    print("hit edge")
                    let center = self.tiledMap.centerOfTile(atColumn: col, row: fromRow)
                    return CGPoint(x: center.x - tiledMap.tileSize.width, y: center.y)
                }
                if tiledMap.tileDefinition(atColumn: col, row: fromRow) != nil {
                    print("already at wall")
                    return nil
                }
                if (tiledMap.tileDefinition(atColumn: col, row: fromRow - 1) == nil) || (tiledMap.tileDefinition(atColumn: col, row: fromRow + 1) == nil) || (tiledMap.tileDefinition(atColumn: col - 1, row: fromRow) != nil) {
                    return self.tiledMap.centerOfTile(atColumn: col, row: fromRow)
                }
            }
            return nil
        case .Up:
            if fromRow >= tiledMap.numberOfRows && tiledMap.tileDefinition(atColumn: fromCol, row: 0) == nil {
                
                let center = self.tiledMap.centerOfTile(atColumn: fromCol, row: fromRow)
                let toPoint = CGPoint(x: center.x, y: center.y + tiledMap.tileSize.height)
                print("fromRow > top; sending to \(toPoint)")
                return toPoint
            }
            for row in (fromRow + 1 < tiledMap.numberOfRows ? fromRow + 1 : fromRow)..<tiledMap.numberOfRows {
                //print("row: \(row) def: \(tiledMap.tileDefinition(atColumn: fromCol, row: row))")
                if row == tiledMap.numberOfRows - 1 && tiledMap.tileDefinition(atColumn: fromCol, row: row) == nil {
                    print("hit edge")
                    let center = self.tiledMap.centerOfTile(atColumn: fromCol, row: row)
                    return CGPoint(x: center.x, y: center.y + tiledMap.tileSize.height)
                }
                if tiledMap.tileDefinition(atColumn: fromCol, row: row) != nil {
                    print("already at wall")
                    return nil
                }
                if (tiledMap.tileDefinition(atColumn: fromCol - 1, row: row) == nil) || (tiledMap.tileDefinition(atColumn: fromCol + 1, row: row) == nil) || (tiledMap.tileDefinition(atColumn: fromCol, row: row + 1) != nil) {
                    return self.tiledMap.centerOfTile(atColumn: fromCol, row: row)
                }
            }
            return nil
        case .Down:
            print("trying to find decision point down")
            if fromRow < 1 && tiledMap.tileDefinition(atColumn: fromCol, row: tiledMap.numberOfRows - 1) == nil {
                
                let center = self.tiledMap.centerOfTile(atColumn: fromCol, row: fromRow)
                print("center: \(center)")
                print("height: \(tiledMap.tileSize.height)")
                let toPoint = CGPoint(x: center.x, y: -tiledMap.tileSize.height)
                print("fromRow < 1; sending to \(toPoint)")
                return toPoint
            }
            for row in (0..<(fromRow > 0 ? fromRow : 0)).reversed() {
                //print("row: \(row) def: \(tiledMap.tileDefinition(atColumn: fromCol, row: row))")
                // edge
                if row == 0 && tiledMap.tileDefinition(atColumn: fromCol, row: row) == nil {
                    print("hit edge")
                    let center = self.tiledMap.centerOfTile(atColumn: fromCol, row: row)
                    return CGPoint(x: center.x, y: center.y - tiledMap.tileSize.height)
                }
                // already at wall
                if tiledMap.tileDefinition(atColumn: fromCol, row: row) != nil {
                    print("already at wall")
                    return nil
                }
                // new decision point
                if (tiledMap.tileDefinition(atColumn: fromCol - 1, row: row) == nil) || (tiledMap.tileDefinition(atColumn:
                    fromCol + 1, row: row) == nil) || (tiledMap.tileDefinition(atColumn: fromCol, row: row - 1) != nil) {
                    print("found decision point")
                    return self.tiledMap.centerOfTile(atColumn: fromCol, row: row)
                }
            }
            print("no match down")
            return nil
        default:  //if .None
            return nil
        }
        
        /*switch (inDirection) {
        case .Right:
            var tempX: CGFloat
            if (fromLocation.x < 0) {  //deal with negative values
                tempX = tiledMap.tileSize.width / 2
            } else {
                tempX = round(fromLocation.x) + (tiledMap.tileSize.width - (round(fromLocation.x).truncatingRemainder(dividingBy: tiledMap.tileSize.width))) + (tiledMap.tileSize.width / 2)
            }
            if (tiledMap.tileDefinition(atColumn: CGPoint(x: tempX, y: fromLocation.y)) != nil) {
                //println("something here at \(tempX), \(fromLocation.y)!")
                return nil
            } else if (tempX > tiledMap.mapSize.width - tiledMap.tileSize.width) {  //deal with edge of board
                return CGPoint(x: tempX, y: fromLocation.y)
            }
            for _ in 0...Int(tiledMap.mapSize.width) { //var i:CGFloat = 0; i <= tiledMap.mapSize.width; i++ {
                if (wallLayer.tile(at: CGPoint(x: tempX, y: fromLocation.y - tiledMap.tileSize.height)) == nil) || (wallLayer.tile(at: CGPoint(x: tempX, y: fromLocation.y + tiledMap.tileSize.height)) == nil) || (wallLayer.tile(at: CGPoint(x: tempX + tiledMap.tileSize.width, y: fromLocation.y)) != nil) {
                    return CGPoint(x: tempX, y: fromLocation.y)
                }
                tempX += tiledMap.tileSize.width
            }
            return nil
        case .Left:
            var tempX = round(fromLocation.x) - (round(fromLocation.x).truncatingRemainder(dividingBy: tiledMap.tileSize.width)) - (tiledMap.tileSize.width / 2)
            if (tempX == fromLocation.x) {
                tempX -= tiledMap.tileSize.width
            }
            if (wallLayer.tile(at: CGPoint(x: tempX, y: fromLocation.y)) != nil) {
                return nil
            } else if (tempX < tiledMap.tileSize.width) {  //deal with edge of board
                return CGPoint(x: tempX, y: fromLocation.y)
            }
            for _ in 0...Int(tiledMap.mapSize.width) {
                if (wallLayer.tile(at: CGPoint(x: tempX, y: fromLocation.y - tiledMap.tileSize.height)) == nil) || (wallLayer.tile(at: CGPoint(x: tempX, y: fromLocation.y + tiledMap.tileSize.height)) == nil) || (wallLayer.tile(at: CGPoint(x: tempX - tiledMap.tileSize.width, y: fromLocation.y)) != nil) {
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
                tempY = round(fromLocation.y) + (tiledMap.tileSize.height - (round(fromLocation.y).truncatingRemainder(dividingBy: tiledMap.tileSize.height))) + (tiledMap.tileSize.height / 2)
            }
            if (wallLayer.tile(at: CGPoint(x: fromLocation.x, y: tempY)) != nil) {
                return nil
            } else if (tempY > tiledMap.mapSize.height - tiledMap.tileSize.height) {  //deal with edge of board
                return CGPoint(x: fromLocation.x, y: tempY)
            }
            for _ in 0...Int(tiledMap.mapSize.height) {
                if (wallLayer.tile(at: CGPoint(x: fromLocation.x - tiledMap.tileSize.width, y: tempY)) == nil) ||
                    (wallLayer.tile(at: CGPoint(x: fromLocation.x + tiledMap.tileSize.width, y: tempY )) == nil) ||
                    (wallLayer.tile(at: CGPoint(x: fromLocation.x, y: tempY + tiledMap.tileSize.height)) != nil) {
                    return CGPoint(x: fromLocation.x, y: tempY)
                }
                tempY += tiledMap.tileSize.height
            }
            return nil
        case .Down:
            var tempY = round(fromLocation.y) - (round(fromLocation.y).truncatingRemainder(dividingBy: tiledMap.tileSize.height)) - (tiledMap.tileSize.height / 2)
            if (tempY == fromLocation.y) {
                
                tempY -= tiledMap.tileSize.height
            }
            //println("Testing wallLayer at \(tempY)");
            if (wallLayer.tile(at: CGPoint(x: fromLocation.x, y: tempY)) != nil) {
                //println("something here at \(fromLocation.x), \(tempY))!")
                return nil
            } else if (tempY < tiledMap.tileSize.height) {  //deal with edge of board
                return CGPoint(x: fromLocation.x, y: tempY)
            }
            for _ in 0...Int(tiledMap.mapSize.height) {
                //println("Testing \(tempY)");
                if (wallLayer.tile(at: CGPoint(x: fromLocation.x - tiledMap.tileSize.width, y: tempY)) == nil) ||
                    (wallLayer.tile(at: CGPoint(x: fromLocation.x + tiledMap.tileSize.width, y: tempY )) == nil) ||
                    (wallLayer.tile(at: CGPoint(x: fromLocation.x, y: tempY - tiledMap.tileSize.height)) != nil) {
                    return CGPoint(x: fromLocation.x, y: tempY)
                }
                tempY -= tiledMap.tileSize.height
            }
            return nil
        default:  //if .None
            return nil
        }*/
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        pause()
    }
    
    override func keyDown(with theEvent: NSEvent) {
        let temp: String = theEvent.characters!
        for letter in temp.characters {
            switch (letter) {
            case "p":
                pause()
            default:
                for player in players {
                    if let tempDirection = player.keyBindings["\(letter)"] {
                        player.wantToGo = tempDirection
                        if (player.direction == .None || player.wantToGo == player.direction.opposite) {  //if player's not moving, move him
                            print("trying to move")
                            player.move()
                        }
                    }
                }
            }
        }
        
        //check if None currently then move
        
        //check if trying to go opposite direction, then do so immediately
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
    }
    
    //MARK: SKPhysics Delegate
    //var times: Int = 1
    func didBegin(_ contact: SKPhysicsContact) {
        let a: SKPhysicsBody = contact.bodyA
        //let b: SKPhysicsBody = contact.bodyB
        if (a.categoryBitMask == PhysicsCategory.Player) {
            //println("Player hit something \(times)")
            //times++
            return
        }
    }
}
