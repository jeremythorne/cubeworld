import Foundation

let app = App()

enum State {
    case demo
    case play
}

class WalkAnimation {
    let length = 0.5
    let twopi = 3.14159 * 2
    func get(timer:Double) -> Vec3 {
        let a = timer * twopi / length
        return Vec3(
            x:0,
            y:sin(a) * 0.05,
            z:0)
    }
}

class MyGame : Game {
    var worldSize = Vec3()
    var p = Vec3()
    var pa:Double = 0
    var timer:Double = 0
    var state = State.demo
    var walk = WalkAnimation()

    override func setup() {
        worldSize = app.worldSize()
    }

    override func update() {
        switch state {
        case .demo:
            pa += 0.01
            p.x = worldSize.x / 2 + 40 * cos(pa)
            p.z = worldSize.z / 2 + 40 * sin(pa)
            p.y = worldSize.y
            if app.keyPressed(key:.Space) {
                state = .play
                p.x = worldSize.x / 2
                p.z = worldSize.z / 2
                timer = 0
            }
        case .play:
            var moving = false
            if app.keyPressed(key:.Left) {
                pa -= 0.01
            } else if app.keyPressed(key:.Right) {
                pa += 0.01
            }
            if app.keyPressed(key:.Up) {
                p.x -= 0.1 * cos(pa)
                p.z -= 0.1 * sin(pa)
                moving = true
            } else if app.keyPressed(key:.Down) {
                p.x += 0.1 * cos(pa)
                p.z += 0.1 * sin(pa)
                moving = true
            }
            if moving {
                timer += 1.0 / 60
            }
            p.x = (min(worldSize.x, max(0, p.x)))
            p.z = (min(worldSize.z, max(0, p.z)))
            p.y = app.mapHeight(x:p.x,z:p.z) + 2.5
        }
        let camera = p + walk.get(timer:timer)

        app.setCamera(p:camera, az:pa)
    }

    override func draw(viewProjection:Mat4) {
    }
}

print("Hello, world!")

app.run(game:MyGame())
