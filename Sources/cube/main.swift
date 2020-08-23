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
    var p = Camera()
    var mouse:Vec3?
    let pi = 3.1416
    var timer:Double = 0
    var state = State.demo
    var walk = WalkAnimation()

    override func setup() {
    }

    override func update() {
        switch state {
        case .demo:
            p.ay += 0.01
            p.ax = -pi / 4
            p.pos.x = 40 * cos(p.ay)
            p.pos.z = 40 * sin(p.ay)
            p.pos.y = 32
            if app.keyPressed(key:.Space) {
                state = .play
                p.pos.x = 0
                p.pos.z = 0
                p.ay = 0
                p.ax = 0
                timer = 0
            }
        case .play:
            var moving = false
            if app.keyPressed(key:.Left) || app.keyPressed(key:.a) {
                p.pos.x -= 0.1 * cos(p.ay)
                p.pos.z -= 0.1 * sin(p.ay)
                moving = true
            } else if app.keyPressed(key:.Right) || app.keyPressed(key:.d){
                p.pos.x += 0.1 * cos(p.ay)
                p.pos.z += 0.1 * sin(p.ay)
                moving = true
            }
            if app.keyPressed(key:.Up) || app.keyPressed(key:.w) {
                p.pos.x += 0.1 * sin(p.ay)
                p.pos.z -= 0.1 * cos(p.ay)
                moving = true
            } else if app.keyPressed(key:.Down) || app.keyPressed(key:.s) {
                p.pos.x -= 0.1 * sin(p.ay)
                p.pos.z += 0.1 * cos(p.ay)
                moving = true
            }
            if let app_mouse = app.mouse {
                if let m = mouse {
                    if app_mouse.x != m.x {
                        p.ay += (app_mouse.x - m.x) / 200
                    }
                    if app_mouse.y != m.y {
                        p.ax -= (app_mouse.y - m.y) / 200
                        p.ax = max(-pi / 2, min(pi / 2, p.ax))
                    }
                }
                mouse = app_mouse
            }
            if moving {
                timer += 1.0 / 60
            }
            p.pos.y = app.mapHeight(x:p.pos.x,z:p.pos.z) + 2.5
        }
        var camera = p
        camera.pos = camera.pos + walk.get(timer:timer)

        app.setCamera(camera)
    }

    override func draw(viewProjection:Mat4) {
    }
}

print("Hello, world!")

app.run(game:MyGame())
