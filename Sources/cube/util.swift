#if os(OSX)
  import OpenGL
#else
  import GL
#endif

struct Image {
    var width:Int = 0
    var height:Int = 0
    var texture:GLuint = 0
}

struct Vec3 {
    var x:Double = 0
    var y:Double = 0
    var z:Double = 0

    func add (_ b:Vec3) -> Vec3 {
        return Vec3(x:x + b.x,
                    y:y + b.y,
                    z:z + b.z)
    }
}

extension Vec3 {
    static func + (left:Vec3, right:Vec3) -> Vec3 {
        return left.add(right)
    }
}

class Mat4 {
    var a = [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0 ]

    init() {
    }

    func mult(_ b:Mat4) -> Mat4 {
        let c = [
            a[0] * b.a[0] + a[1] * b.a[4] + a[2] * b.a[8] + a[3] * b.a[12],
            a[0] * b.a[1] + a[1] * b.a[5] + a[2] * b.a[9] + a[3] * b.a[13],
            a[0] * b.a[2] + a[1] * b.a[6] + a[2] * b.a[10] + a[3] * b.a[14],
            a[0] * b.a[3] + a[1] * b.a[7] + a[2] * b.a[11] + a[3] * b.a[15],

            a[4] * b.a[0] + a[5] * b.a[4] + a[6] * b.a[8] +  a[7] * b.a[12],
            a[4] * b.a[1] + a[5] * b.a[5] + a[6] * b.a[9] +  a[7] * b.a[13],
            a[4] * b.a[2] + a[5] * b.a[6] + a[6] * b.a[10] + a[7] * b.a[14],
            a[4] * b.a[3] + a[5] * b.a[7] + a[6] * b.a[11] + a[7] * b.a[15],

            a[8] * b.a[0] + a[9] * b.a[4] + a[10] * b.a[8] +  a[11] * b.a[12],
            a[8] * b.a[1] + a[9] * b.a[5] + a[10] * b.a[9] +  a[11] * b.a[13],
            a[8] * b.a[2] + a[9] * b.a[6] + a[10] * b.a[10] + a[11] * b.a[14],
            a[8] * b.a[3] + a[9] * b.a[7] + a[10] * b.a[11] + a[11] * b.a[15],

            a[12] * b.a[0] + a[13] * b.a[4] + a[14] * b.a[8] +  a[15] * b.a[12],
            a[12] * b.a[1] + a[13] * b.a[5] + a[14] * b.a[9] +  a[15] * b.a[13],
            a[12] * b.a[2] + a[13] * b.a[6] + a[14] * b.a[10] + a[15] * b.a[14],
            a[12] * b.a[3] + a[13] * b.a[7] + a[14] * b.a[11] + a[15] * b.a[15],
        ]
        a = c
        return self
    }

    init (projection:(right:Double, aspect:Double, near:Double, far:Double)) {
        let (right, aspect, near, far) = projection
        for i in 0..<16 {
            a[i] = 0
        }
        let top = right / aspect
        a[0] = near / right
        a[5] = near / top
        a[10] = -(far + near) / (far - near)
        a[11] = -2 * far * near / (far - near)
        a[14] = -1
    }

    init(translate t:(x:Double, y:Double, z:Double)) {
        a[12] = t.x
        a[13] = t.y
        a[14] = t.z
    }

    init(rotatey rad:Double) {
        a[0] = sin(rad)
        a[2] = cos(rad)
        a[8] = -cos(rad)
        a[10] = sin(rad)
    }

    func toGL() -> [GLfloat] {
        let glf:[GLfloat] = [
            GLfloat(a[0]),  GLfloat(a[1]),  GLfloat(a[2]),  GLfloat(a[3]),
            GLfloat(a[4]),  GLfloat(a[5]),  GLfloat(a[6]),  GLfloat(a[7]),
            GLfloat(a[8]),  GLfloat(a[9]),  GLfloat(a[10]), GLfloat(a[11]),
            GLfloat(a[12]), GLfloat(a[13]), GLfloat(a[14]), GLfloat(a[15])
        ]
        return glf
    }
}

extension Mat4 {
    static func * (left:Mat4, right:Mat4) -> Mat4 {
        return left.mult(right)
    }
}

func compileShader(text:String, shader_type:GLenum) -> GLuint? {
    let shader = glCreateShader(shader_type)
    text.withCString {cs in
        var cs_opt = Optional(cs)
        glShaderSource(shader, 1, &cs_opt, nil)
    }
    glCompileShader(shader)
    var compile_status:GLint = 0
    glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compile_status)
    if compile_status != GLboolean(GL_TRUE) {
        print("shader compile failed")
        var buffer = [Int8]()
        buffer.reserveCapacity(256)
        var length: GLsizei = 0
        glGetShaderInfoLog(shader, 256, &length, &buffer)
        print(String(cString: buffer))
        return nil
    }
    return shader
}

func loadTexture(width:Int, height:Int, bytes: inout [UInt8]) -> GLuint {
    print("loading texture")
    var texture:GLuint = 0
    glGenTextures(1, &texture)
    glBindTexture(GLenum(GL_TEXTURE_2D), texture)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)

    glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA,
                 Int32(width), Int32(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE),
                 &bytes)
    glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    return texture
}

func loadImage(filename:String) -> Image?
{
    guard let png = try? PNG(filename:filename) else {
        return nil
    }
    var image = Image()
    image.width = png.width
    image.height = png.height
    image.texture = loadTexture(width:image.width, height:image.height, bytes:&png.bytes)
    return image
}

func enableAttrib(loc:GLint, num:Int, off:Int, stride:Int)
{
    glEnableVertexAttribArray(GLuint(loc))
    glVertexAttribPointer(GLuint(loc), GLint(num), GLenum(GL_BYTE), GLboolean(GL_FALSE),
                            GLsizei(MemoryLayout<GLbyte>.size * stride),
                                       UnsafeRawPointer(bitPattern: MemoryLayout<GLbyte>.size * off))
}
