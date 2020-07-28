#if os(OSX)
  import OpenGL
#else
  import GL
#endif

var cube: [[[GLbyte]]] = [
     [ // front
     [0, 0, 1,  1, 1],
     [1, 0, 1,  0, 1], 
     [1, 1, 1,  0, 0], 
     [0, 1, 1,  1, 0], 
     ], 

     [ //left
     [0, 0, 0,  2, 1],
     [0, 0, 1,  1, 1], 
     [0, 1, 1,  1, 0], 
     [0, 1, 0,  2, 0], 
     ], 

     [ // back
     [1, 0, 0,   3, 1],
     [0, 0, 0,   2, 1], 
     [0, 1, 0,   2, 0], 
     [1, 1, 0,   3, 0], 
     ], 

     [ //right
     [1, 0, 1,  4, 1],
     [1, 0, 0,  3, 1], 
     [1, 1, 0,  3, 0], 
     [1, 1, 1,  4, 0], 
     ], 

     [ // bottom
     [0, 0, 0,  5, 0], 
     [1, 0, 0,  6, 0], 
     [1, 0, 1,  6, 1],
     [0, 0, 1,  5, 1], 
     ], 

     [ //top
     [0, 1, 1,  4, 0], 
     [1, 1, 1,  5, 0],
     [1, 1, 0,  5, 1], 
     [0, 1, 0,  4, 1], 
     ]
]

var normals: [[GLfloat]] = [
     [ 0,  0,  1], 
     [-1,  0,  0], 
     [ 0,  0, -1], 
     [ 1,  0,  0], 
     [0,  -1,  0], 
     [0,   1,  0], 
]

var vertex_shader_text = "#version 110\n"
+ "attribute vec3 pos;\n"
+ "attribute vec2 tex_coord;\n"
+ "uniform vec3 normal;\n"
+ "uniform mat4 mvp;\n"
+ "varying vec2 vtex_coord;\n"
+ "varying float vsky;\n"
+ "varying float v;\n"
+ "void main()\n"
+ "{\n"
+ "  vec4 p = mvp * vec4(pos, 1.0);\n"
+ "  gl_Position = p;\n"
+ "  v = p.z / p.w;\n"
+ "  vtex_coord = tex_coord / vec2(6.0, 3.0);\n"
+ "  vsky = max(0.0, dot(normal, vec3(0.8, 0.7, 1.0)));\n"
+ "}\n"

var fragment_shader_text = "#version 110\n"
+ "varying vec2 vtex_coord;\n"
+ "varying float vsky;\n"
+ "varying float v;\n"
+ "uniform sampler2D image;\n"
+ "void main()\n"
+ "{\n"
+ "  vec4 tex = texture2D(image, vtex_coord);\n"
+ "  vec3 ambient = vec3(0.2, 0.2, 0.2);\n"
+ "  vec4 fog = vec4(vec3(v), 0.0);\n"
+ "  gl_FragColor = fog + vec4((ambient + vsky) * tex.xyz, tex.w);\n"
+ "}\n"

enum CubeType:Int {
    case sky = 0
    case grass = 1
    case stone = 2
    case water = 3
}

struct Cube {
    var type:CubeType = .sky
    var occluded:Bool = false
}

class Chunk {
    var vertex_buffer: [GLuint] = [0, 0, 0, 0, 0, 0]
    var bytes:[[GLbyte]] = [[], [], [], [], [], []]
    var cubes:[[[Cube]]]
    var vertex_count:Int = 0
    var xoff:Int
    var zoff:Int
    var height:Int

    init(xoff:Int, zoff:Int, world:[[[CubeType]]]) {
        self.xoff = xoff
        self.zoff = zoff
        let width = world[0].count
        let depth = world.count
        height = world[0][0].count
        let sky = Cube()
        cubes = [[[Cube]]](repeating:[[Cube]](repeating:[Cube](repeating:sky, count: height), count:16), count:16)

        func occluded(_ x:Int, _ y:Int, _ z:Int) -> Bool {
            if x == 0 || x == (width - 1) || z == 0 || z == (depth - 1) || y == 0 || y == (height - 1) ||
                   world[z - 1][x][y] == .sky ||
                   world[z + 1][x][y] == .sky ||
                   world[z][x - 1][y] == .sky ||
                   world[z][x + 1][y] == .sky ||
                   world[z][x][y - 1] == .sky ||
                   world[z][x][y + 1] == .sky {
                       // not completely occluded
                       return false
            }
            return true
        }

        for z in zoff..<(zoff + 16) {
            for x in xoff..<(xoff + 16) {
                for y in 0..<height {
                    cubes[z - zoff][x - xoff][y].type = world[z][x][y]
                    cubes[z - zoff][x - xoff][y].occluded = occluded(x, y, z)
                }
            }
        }

        makeGeometry()

    }

    func makeGeometry() {
        for z in 0..<16 {
            for x in 0..<16 {
                for y in 0..<height {
                    let cube = cubes[z][x][y]
                    if cube.type != .sky && !cube.occluded {
                        addCubeVertices(x:x, y:y, z:z, type:cube.type)
                    }
                }
            }
        }

        for i in 0..<6 {
            glGenBuffers(1, &vertex_buffer[i])
        }

        uploadCubeVertices()
    }

    func addCubeVertices(x:Int, y:Int, z:Int, type:CubeType)
    {
        // vertex must fix in a byte
        assert(x >= -128 && x < 127)
        assert(y >= -128 && y < 127)
        assert(z >= -128 && z < 127)
        let tv = GLbyte(type.rawValue - 1)
        for i in 0..<6 {
            var verts = [[GLbyte]]()
            for j in 0..<4 {
                let v = cube[i][j]
                verts.append([v[0] + GLbyte(x), v[1] + GLbyte(y), v[2] + GLbyte(z), v[3], v[4] + tv])
            }

            for j in [0, 1, 2, 0, 2, 3] {
                bytes[i] += verts[j]
            }
        }
        vertex_count += 6
    }

    func uploadCubeVertices()
    {
        for i in 0..<6 {
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertex_buffer[i])
            glBufferData(GLenum(GL_ARRAY_BUFFER),
                         GLsizeiptr(MemoryLayout<GLbyte>.size * Int(bytes[i].count)),
                                               bytes[i], GLenum(GL_STATIC_DRAW))
        }
    }

}

class World {

    let worldWidth = 128
    let worldHeight = 16
    let worldDepth = 128
    var program:GLuint = 0
    var pos_location:GLint = 0
    var normal_location:GLint = 0 
    var tex_coord_location:GLint = 0
    var mvp_location:GLint = 0 
    var map = [[Int]]()
    var chunks = [[Chunk]]()
        
    func setup() -> Bool
    {
        guard let vertex_shader = 
            compileShader(text: vertex_shader_text,
                          shader_type:GLenum(GL_VERTEX_SHADER)) else {
                return false
        }

        guard let fragment_shader = 
            compileShader(text: fragment_shader_text,
                          shader_type:GLenum(GL_FRAGMENT_SHADER)) else {
                return false
        }

        program = glCreateProgram()
        glAttachShader(program, vertex_shader)
        glAttachShader(program, fragment_shader)
        glLinkProgram(program)
        var link_status:GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &link_status)
        if link_status != GLboolean(GL_TRUE) {
            print("failed to link GL program")
            return false
        }

        pos_location = GLint(glGetAttribLocation(program, "pos"))
        tex_coord_location = GLint(glGetAttribLocation(program, "tex_coord"))
        normal_location = GLint(glGetUniformLocation(program, "normal"))
        mvp_location = GLint(glGetUniformLocation(program, "mvp")) 

        print("program attribute locations", pos_location,tex_coord_location)

        let image = loadImage(filename:"images/hello.png")!
        glBindTexture(GLenum(GL_TEXTURE_2D), image.texture)
        
        makeWorld(width:worldWidth, depth:worldDepth, height:worldHeight)
        return true
    }

    func heightMap(width:Int, depth:Int, height:Int) -> [[Int]]
    {
        func is_power_of_two(_ a:Int) -> Bool
        {
            return a > 0 && (a & (a - 1)) == 0
        }

        assert(is_power_of_two(width - 1))
        assert(width == depth)
        // this algorithm only works if width and depth are 2^n + 1
        var h = [[Int]](repeating:[Int](repeating:0, count: depth), count: width)
        func diamondSquare(s:Int, n:Int)
        {
            let m = s / 2
            let n2 = n / 2
            for x in stride(from: 0, to: width - s, by: s) {
                for y in stride(from: 0, to: depth - s, by: s) {
                    h[x + m][y + m] = max(1, min(height, (h[x][x] + 
                                                          h[x + s][y + s] +
                                                          h[x + s][y] +
                                                          h[x][y + s]) / 4 + Int.random(in:-n2...n2)))
                    h[x + m][y] = max(1, min(height, (h[x][y] + h[x + s][y]) / 2 + Int.random(in:-n2...n2)))
                    h[x + m][y + s] = max(1, min(height, (h[x][y + s] + h[x + s][y + s]) / 2 + Int.random(in:-n2...n2))) 
                    h[x][y + m] = max(1, min(height, (h[x][y] + h[x][y + s]) / 2 + Int.random(in:-n2...n2)))
                    h[x + s][y + m] = max(1, min(height, (h[x + s][y] + h[x + s][y + s]) / 2 + Int.random(in:-n2...n2)))
            
                }
            }
        }

        var n = height
        h[0][0] = Int.random(in:1...n) 
        h[0][depth - 1] = Int.random(in:1...n) 
        h[width - 1][0] = Int.random(in:1...n) 
        h[width - 1][depth - 1] = Int.random(in:1...n)
        var s = width - 1
        while s > 1 {
            n /= 2
            diamondSquare(s:s, n:n)
            s /= 2
        }
        return h
    }

    func makeWorld(width:Int, depth:Int, height:Int)
    {
        
        var world = [[[CubeType]]](repeating:[[CubeType]](repeating:[CubeType](repeating:.sky, count: height), count:width), count:depth)

        map = heightMap(width:width + 1, depth:depth + 1, height:height)

        for z in 0..<depth {
            for x in 0..<width {
                var h = map[x][z]
                if h < 6 {
                    h = 6
                    map[x][z] = 6
                }
                for y in 0..<height {
                    let t:CubeType
                    switch y {
                    case 0..<h:
                        t = .stone
                    case h:
                        if h <= 6 {
                            t = .water
                        }else {
                            t = .grass
                        }
                    default:
                        t = .sky
                    }
                    world[z][x][y] = t
                }
            }
        }

        for i in 0..<(depth/16) {
            chunks.append([Chunk]())
            for j in 0..<(width/16) {
                print("chunk \(i),\(j)")
                chunks[i].append(Chunk(xoff:j * 16, zoff:i * 16, world:world))
            }
        } 

    }

    func draw(vp:Mat4)
    {
        glUseProgram(program)

        for i in 0..<chunks.count {
            for j in 0..<chunks[i].count {
                drawChunk(vp:vp, chunk:chunks[i][j])
            }
        }
    }

    func drawChunk(vp:Mat4, chunk:Chunk) {
        let mvp = Mat4(translate:(Double(chunk.xoff), 0, Double(chunk.zoff))) * vp
        var glmat4 = mvp.toGL()
        glUniformMatrix4fv(mvp_location, 1, GLboolean(GL_FALSE), &glmat4)

        for i in 0..<6 {
            glUniform3fv(normal_location, 1, normals[i])
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), chunk.vertex_buffer[i])
            enableAttrib(loc:pos_location, num:3, off:0, stride:5)
            enableAttrib(loc:tex_coord_location, num:2, off:3, stride:5)
            glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(chunk.vertex_count))
        }
    }
}

