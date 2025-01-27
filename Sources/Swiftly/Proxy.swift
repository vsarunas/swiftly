import Foundation
import SwiftlyCore

@main
public enum Proxy {
    static func main() async throws {
        do {
            let zero = CommandLine.arguments[0]
            guard let binName = zero.components(separatedBy: "/").last else {
                fatalError("Could not determine the binary name for proxying")
            }

            guard binName != "swiftly" else {
                // Treat this as a swiftly invocation
                await Swiftly.main()
                return
            }

            var config = try Config.load()

            let (toolchain, result) = try await selectToolchain(config: &config)

            // Abort on any errors relating to swift version files
            if case let .swiftVersionFile(_, _, error) = result, let error = error {
                throw error
            }

            guard let toolchain = toolchain else {
                throw Error(message: "No swift toolchain could be selected from either from a .swift-version file, or the default. You can try using `swiftly install <toolchain version>` to install one.")
            }

            try await Swiftly.currentPlatform.proxy(toolchain, binName, Array(CommandLine.arguments[1...]))
        } catch let terminated as RunProgramError {
            exit(terminated.exitCode)
        } catch let error as Error {
            SwiftlyCore.print(error.message)
            exit(1)
        } catch {
            SwiftlyCore.print("\(error)")
            exit(1)
        }
    }
}
