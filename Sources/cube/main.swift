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
    var p = Vec3()
    var pa:Double = 0
    var timer:Double = 0
    var state = State.demo
    var walk = WalkAnimation()

    override func setup() {
    }

    override func update() {
        switch state {
        case .demo:
            pa += 0.01
            p.x = 40 * cos(pa)
            p.z = 40 * sin(pa)
            p.y = 32
            if app.keyPressed(key:.Space) {
                state = .play
                p.x = 0
                p.z = 0
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
