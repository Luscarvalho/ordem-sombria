import Foundation
import ImageIO
import UniformTypeIdentifiers

struct CharacterPreview: Decodable {
    let id: String
    let frames: String
    let output: String
    let fps: Double
    let frame_count: Int
}

struct PreviewManifest: Decodable {
    let characters: [CharacterPreview]
}

let manifestURL = URL(fileURLWithPath: CommandLine.arguments[1])
let manifest = try JSONDecoder().decode(PreviewManifest.self, from: Data(contentsOf: manifestURL))

for character in manifest.characters {
    let outputURL = URL(fileURLWithPath: character.output)
    guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.gif.identifier as CFString, character.frame_count, nil) else {
        fatalError("Could not create GIF: \(character.output)")
    }
    CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
    var elapsedCentiseconds = 0
    for frameIndex in 0..<character.frame_count {
        let nextCentiseconds = Int((Double(frameIndex + 1) * 100.0 / character.fps).rounded())
        let delay = Double(nextCentiseconds - elapsedCentiseconds) / 100.0
        elapsedCentiseconds = nextCentiseconds
        let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay, kCGImagePropertyGIFUnclampedDelayTime: delay]] as CFDictionary
        let frameURL = URL(fileURLWithPath: character.frames + String(format: "/frame-%02d.png", frameIndex))
        guard let source = CGImageSourceCreateWithURL(frameURL as CFURL, nil), let frame = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            fatalError("Could not read frame: \(frameURL.path)")
        }
        CGImageDestinationAddImage(destination, frame, properties)
    }
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not finalize GIF: \(character.output)")
    }
    print("ENCODED: \(character.output)")
}
