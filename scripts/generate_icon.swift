import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Could not create the icon context.\n", stderr)
    exit(1)
}

context.setFillColor(CGColor(srgbRed: 0.122, green: 0.329, blue: 0.310, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

context.setFillColor(CGColor(srgbRed: 0.96, green: 0.95, blue: 0.90, alpha: 1))
let line = CGPath(
    roundedRect: CGRect(x: 196, y: 480, width: 500, height: 64),
    cornerWidth: 32,
    cornerHeight: 32,
    transform: nil
)
context.addPath(line)
context.fillPath()
context.fillEllipse(in: CGRect(x: 736, y: 480, width: 64, height: 64))

guard let image = context.makeImage() else {
    fputs("Could not render the icon.\n", stderr)
    exit(1)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
guard let destination = CGImageDestinationCreateWithURL(output, UTType.png.identifier as CFString, 1, nil) else {
    fputs("Could not create the PNG destination.\n", stderr)
    exit(1)
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("Could not write the icon.\n", stderr)
    exit(1)
}
