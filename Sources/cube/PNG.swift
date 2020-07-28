import CLIBPNG

class PNG {
    var width:Int = 0
    var height:Int = 0
    var bytes = [UInt8]()

    enum error:Error {
        case error(message:String)
    }

    init(filename:String) throws {
        var fp: UnsafeMutablePointer<FILE>? = nil
        filename.withCString {cs in fp = fopen(cs, "rb")}
        if fp == nil {
            throw error.error(message: "failed to open:" + filename)
        }
        defer {
            fclose(fp)
        }
        var png = png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
        if png == nil {
            throw error.error(message: "couldn't create struct to read PNG")
        }
        var info = png_create_info_struct(png)
        if info == nil {
            throw error.error(message: "couldn't create info struct to read PNG")
        }
        defer {
            png_destroy_read_struct(&png, &info, nil)
        }

        png_init_io(png, fp)
        png_read_info(png, info)
        self.width = Int(png_get_image_width(png, info))
        self.height = Int(png_get_image_height(png, info))
        let color_type = png_get_color_type(png, info)
        let bit_depth = png_get_bit_depth(png, info)

        if bit_depth == 16 {
            png_set_strip_16(png)
        }
        
        if color_type == PNG_COLOR_TYPE_PALETTE {
            png_set_palette_to_rgb(png)
        }

        if color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8 {
            png_set_expand_gray_1_2_4_to_8(png)
        }

        if png_get_valid(png, info, PNG_INFO_tRNS) == 0 {
            png_set_tRNS_to_alpha(png)
        }

        if [PNG_COLOR_TYPE_RGB,
            PNG_COLOR_TYPE_GRAY,
            PNG_COLOR_TYPE_PALETTE].contains(Int32(color_type)) {
                png_set_filler(png, 0xff, PNG_FILLER_AFTER)
        }

        if [PNG_COLOR_TYPE_GRAY,
            PNG_COLOR_TYPE_GRAY_ALPHA].contains(Int32(color_type)) {
                png_set_gray_to_rgb(png)
        }

        png_read_update_info(png, info)

        let rowbytes = png_get_rowbytes(png, info)
        self.bytes.reserveCapacity(self.height * rowbytes)
        var row_pointers = [Optional<UnsafeMutablePointer<UInt8>>]()
        row_pointers.reserveCapacity(self.height)
        let p = UnsafeMutablePointer<UInt8>(mutating:self.bytes)
        for index in 0..<self.height {
            row_pointers.append(p + index * rowbytes)
        }

        let orp = Optional(UnsafeMutablePointer(mutating:row_pointers))
        png_read_image(png, orp)
    }

}
