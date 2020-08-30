#if os(OSX)
  import OpenGL
#else
  import GL
#endif

var cubeverts: [[[GLubyte]]] = [
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
     [ 0,  0,  1], // front - south
     [-1,  0,  0], // left - west
     [ 0,  0, -1], // back - north
     [ 1,  0,  0], // right -east
     [0,  -1,  0], // bottom
     [0,   1,  0], // top 
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
+ "  vtex_coord = tex_coord / vec2(6.0, 6.0);\n"
+ "  vsky = 0.2 * max(0.0, dot(normal, vec3(0.8, 0.7, 1.0)));\n"
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
    case sand = 4
    case wood = 5
    case leaf = 6
}

struct Cube {
    var type:CubeType = .sky
    var occluded:Bool = false
}

class Chunk {
    var vertex_buffer: [GLuint] = [0, 0, 0, 0, 0, 0]
    var bytes:[[GLubyte]] = [[], [], [], [], [], []]
    var cubes:[[[Cube]]]
    var vertex_count:Int = 0
    var xoff:Int
    var zoff:Int
    var height:Int = 256

    init(xoff:Int, zoff:Int, map:(Int, Int) -> Int,
            trees:(Int, Int) -> [Tree]) {
        self.xoff = xoff
        self.zoff = zoff
        let sky = Cube()
        cubes = [[[Cube]]](repeating:[[Cube]](repeating:[Cube](repeating:sky, count: height), count:16), count:16)

        for z in 0..<16 {
            for x in 0..<16 {
                let h = map(x + xoff, z + zoff)
                for y in 0...max(6, h) {
                    let t:CubeType
                    switch y {
                    case 0..<h:
                        t = .stone
                    case h:
                        if h == 6 {
                            t = .sand
                        } else {
                            t = .grass
                        }
                    case (h + 1)...6:
                        t = .water
                    default:
                        t = .sky
                    }
                    cubes[z][x][y].type = t
                }
            }
        }

        addTrees(map, trees(xoff, zoff))

        calcOcclusion()
        makeGeometry()
    }

    func addTrees(_ map:(Int, Int) -> Int, _ trees:[Tree]) {
        for tree in trees {
            let h = map(tree.x, tree.z)
            for block in tree.blocks {
                let x = block.x + tree.x - xoff
                let y = block.y + h
                let z = block.z + tree.z - zoff
                if x >= 0 && x < 16 &&
                   z >= 0 && z < 16 && 
                   y >= 0 && y < 256 {
                    cubes[z][x][y].type = block.type 
                }
            }
        }
    }

    func occluded(_ x:Int, _ y:Int, _ z:Int) -> Bool {
        if x == 0 || x == 15 || z == 0 || z == 15 || y == 0 || y == height - 1 {
            return false
        }
        if cubes[z + 1][x][y].type == .sky ||
           cubes[z - 1][x][y].type == .sky ||
           cubes[z][x + 1][y].type == .sky ||
           cubes[z][x - 1][y].type == .sky ||
           cubes[z][x][y + 1].type == .sky ||
           cubes[z][x][y - 1].type == .sky {
               return false
        }
        return true
    }

    func calcOcclusion() {
        for z in 0..<16 {
            for x in 0..<16 {
                for y in 0..<height {
                    cubes[z][x][y].occluded = occluded(x, y, z)
                }
            }
        }
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
        assert(x >= 0 && x < 255)
        assert(y >= 0 && y < 255)
        assert(z >= 0 && z < 255)
        let tv = GLubyte(type.rawValue - 1)
        for i in 0..<6 {
            var verts = [[GLubyte]]()
            for j in 0..<4 {
                let v = cubeverts[i][j]
                verts.append([v[0] + GLubyte(x), v[1] + GLubyte(y), v[2] + GLubyte(z), v[3], v[4] + tv])
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

struct Tree {
    var x:Int
    var z:Int
    var seed:Int
    var height:Int {
        return (seed >> 8) & 7 + 4
    }

    struct Block {
        var x:Int
        var y:Int
        var z:Int
        var type:CubeType
    }

    var blocks : [Block] {
        get {
            var blocks = [Block]()
            for y in 0..<height {
                blocks.append(Block(x:0, y:y, z:0, type:.wood))
            }
            let r = height / 3
            for x in -r..<r {
                for z in -r..<r {
                    for y in -r..<r {
                        if leaf(x, y, z) {
                            blocks.append(Block(x:x, y:y + height, z:z, type:.leaf))
                        }
                    }
                }
            }
            return blocks
        }
    }

    func leaf(_ x: Int, _ y:Int, _ z:Int) -> Bool {
        if x == 0 && z == 0 && y < 0 {
            return false
        }
        let a:Int = hash(hash(hash(seed + z) + y) + x)
        return (a & 0xff) < 150
    }
}

struct ChunkPos : Hashable {
    var x:Int
    var z:Int
}

class World {


    let worldSeed = Int.random(in:1...Int.max)
    var mapSeed:Int = 0
    var treeSeed:Int = 0
    var program:GLuint = 0
    var pos_location:GLint = 0
    var normal_location:GLint = 0 
    var tex_coord_location:GLint = 0
    var mvp_location:GLint = 0 
    var map = [[Int]]()
    var chunks = [ChunkPos:Chunk]()

    init() {
        mapSeed = hash(worldSeed)
        treeSeed = hash(worldSeed + 1)
    }
        
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

        let image = loadImage(filename:"images/world.png")!
        glBindTexture(GLenum(GL_TEXTURE_2D), image.texture)
        
        loadChunks(x:0, z:0)
        return true
    }

    func heightMap(_ x:Int, _ z:Int) -> Int
    {
        return Int(noise8_2d(seed: mapSeed, x / 2, z / 2) >> 3)
    }

    func getTrees(_ x:Int, _ z:Int) -> [Tree]
    {
        var trees = [Tree]()
        for zo in (z - 9)..<(z + 24) {
            for xo in (x - 9)..<(x + 24) {
                let tree = getTree(xo, zo)
                if tree != nil {
                    trees.append(tree!)
                }
            }
        }
        return trees
    }

    func getTree(_ x:Int, _ z:Int) -> Tree?
    {
        let a:Int = hash(hash(treeSeed + z) + x)
        if (a & 0xff) > 1 {
            return nil
        }
        return Tree(x:x, z:z, seed:a)
    }

    func loadChunks(x:Int, z:Int)
    {
        let cx = x / 16
        let cz = z / 16
        for i in (cx - 2)...(cx + 2) {
            for j in (cz - 2)...(cz + 2) {
                let pos = ChunkPos(x:i, z:j)
                if chunks[pos] == nil {
                    print("chunk \(i),\(j)")
                    chunks[pos] = Chunk(xoff:i * 16, zoff:j * 16, map:heightMap, trees:getTrees)
                }
            }
        }

        if chunks.count > 64 {
           for pos in chunks.keys {
               let diff = abs(cx - pos.x) + abs(cz - pos.z)
               if diff > 8 {
                   chunks[pos] = nil
               }
               if chunks.count < 64 {
                   break
               }
           }
        } 
    }

    func draw(vp:Mat4)
    {
        glUseProgram(program)

        for chunk in chunks.values {
            drawChunk(vp:vp, chunk:chunk)
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

