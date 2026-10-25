import Foundation

enum ShellError: Error, LocalizedError {
    case commandNotFound(String)
    case executionFailed(Int32, String)

    var errorDescription: String? {
        switch self {
        case .commandNotFound(let cmd):
            return "Command not found: \(cmd)"
        case .executionFailed(let code, let stderr):
            return "Exit \(code): \(stderr)"
        }
    }
}

struct ShellOutput {
    let stdout: String
    let stderr: String
    let exitCode: Int32
    var succeeded: Bool { exitCode == 0 }
}

class ShellHelper {
    
    // Apps launched from Finder or Xcode inherit a minimal PATH that omits Homebrew and other
    // user-installed tool directories. This computed property prepends those common locations so
    // every subprocess we spawn can locate `brew`, `npm`, `pip3`, etc. without relying on the
    // user's interactive shell profile being sourced.
    var augmentedEnvironment: [String: String] {
        var env = ProcessInfo.processInfo.environment
        let extraPaths = [
            "/opt/homebrew/bin",    // Apple Silicon Homebrew (M1/M2/M3)
            "/opt/homebrew/sbin",
            "/usr/local/bin",       // Intel Homebrew & manually installed tools
            "/usr/local/sbin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]
        let existingComponents = (env["PATH"] ?? "").split(separator: ":").map(String.init)
        let existingSet = Set(existingComponents)
        let additions = extraPaths.filter { !existingSet.contains($0) }
        env["PATH"] = (additions + existingComponents).joined(separator: ":")
        return env
    }

    func run(executableURL: URL, arguments: [String]) throws -> String {
        let out = capture(executableURL: executableURL, arguments: arguments)
        if out.succeeded { return out.stdout }
        throw ShellError.executionFailed(out.exitCode, out.stderr)
    }

    func run(command: String, arguments: [String] = []) throws -> String {
        try run(executableURL: URL(fileURLWithPath: command), arguments: arguments)
    }

    /// Always returns stdout and stderr regardless of exit code — useful for commands
    /// like `npm list` that produce valid output with a non-zero exit code.
    func capture(executableURL: URL, arguments: [String]) -> ShellOutput {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.environment = augmentedEnvironment

        do {
            try process.run()
        } catch {
            return ShellOutput(stdout: "", stderr: error.localizedDescription, exitCode: -1)
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        return ShellOutput(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus)
    }

    /// Resolves the full path for a command name.
    ///
    /// First attempts `/usr/bin/which` with the augmented PATH (set via `capture`). If that
    /// fails — e.g., the tool exists but is not on any standard PATH at all — falls back to
    /// checking known absolute installation locations directly using the filesystem, so the
    /// check succeeds regardless of shell environment configuration.
    func which(_ name: String) -> String? {
        let out = capture(executableURL: URL(fileURLWithPath: "/usr/bin/which"), arguments: [name])
        if out.succeeded {
            let path = out.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty { return path }
        }

        // Fallback: probe known absolute paths directly without relying on PATH at all.
        // This covers Xcode CLT, Homebrew (both architectures), pyenv, asdf, conda,
        // and user-local pip installations — all common places where tools land on macOS.
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let knownPaths: [String]
        switch name {
        case "brew":
            knownPaths = [
                "/opt/homebrew/bin/brew",
                "/usr/local/bin/brew",
            ]
        case "npm":
            knownPaths = [
                "/opt/homebrew/bin/npm",
                "/usr/local/bin/npm",
            ]
        case "pip3", "pip":
            knownPaths = [
                // Homebrew (Apple Silicon / Intel)
                "/opt/homebrew/bin/\(name)",
                "/usr/local/bin/\(name)",
                // Xcode Command Line Tools
                "/usr/bin/\(name)",
                // pyenv
                "\(home)/.pyenv/shims/\(name)",
                // asdf
                "\(home)/.asdf/shims/\(name)",
                // Miniconda / Anaconda (user-installed)
                "\(home)/miniconda3/bin/\(name)",
                "\(home)/anaconda3/bin/\(name)",
                "/opt/miniconda3/bin/\(name)",
                "/opt/anaconda3/bin/\(name)",
                // User-local pip (--user install)
                "\(home)/.local/bin/\(name)",
            ]
        default:
            knownPaths = [
                "/opt/homebrew/bin/\(name)",
                "/usr/local/bin/\(name)",
                "/usr/bin/\(name)",
            ]
        }
        return knownPaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}
