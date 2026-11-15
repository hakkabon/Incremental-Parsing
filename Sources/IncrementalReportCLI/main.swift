import Foundation
import IncrementalParsing

private enum ReportCLIError: Error, CustomStringConvertible {
    case usage
    case evidenceMismatch([String])
    case budgetFailure([String])
    case invalidPackageDump(String)

    var description: String {
        switch self {
        case .usage:
            return """
            Usage:
              incremental-report verify REPORT.json
              incremental-report compare REPORT.json REPORT.json [REPORT.json ...]
              incremental-report gate REPORT.json BUDGETS.json
              incremental-report release-manifest MANIFEST.json
              incremental-report release-dependencies PACKAGE-DUMP.json [PACKAGE-DUMP.json ...]
            """
        case .evidenceMismatch(let paths):
            return "Evidence fingerprints differ: \(paths.joined(separator: ", "))"
        case .budgetFailure(let violations):
            return violations.joined(separator: "\n")
        case .invalidPackageDump(let path):
            return "Invalid SwiftPM package dump: \(path)"
        }
    }
}

@main
private struct IncrementalReportCLI {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first else { throw ReportCLIError.usage }
        switch command {
        case "verify" where arguments.count == 2:
            let report = try loadReport(arguments[1])
            print("Verified evidence \(report.evidenceFingerprint), measurement \(report.measurementFingerprint)")
            for summary in report.summaries {
                print("\(summary.scenarioID): median \(summary.medianNanoseconds) ns, p95 \(summary.percentile95Nanoseconds) ns, \(summary.correctnessFailureCount) correctness failures")
            }
        case "compare" where arguments.count >= 3:
            let paths = Array(arguments.dropFirst())
            let reports = try paths.map(loadReport)
            guard Set(reports.map(\.evidenceFingerprint)).count == 1 else {
                throw ReportCLIError.evidenceMismatch(paths)
            }
            let timingComparable = reports.dropFirst().allSatisfy {
                reports[0].isTimingComparable(to: $0)
            }
            print("Equivalent evidence \(reports[0].evidenceFingerprint)")
            print("Timing comparable: \(timingComparable ? "yes" : "no")")
        case "gate" where arguments.count == 3:
            let report = try loadReport(arguments[1])
            let budgets = try JSONDecoder().decode(
                [IncrementalMeasurementBudget].self,
                from: Data(contentsOf: URL(fileURLWithPath: arguments[2])))
            let evaluation = report.evaluate(budgets)
            guard evaluation.passed else {
                throw ReportCLIError.budgetFailure(evaluation.violations)
            }
            print("All \(budgets.count) measurement budgets passed")
        case "release-manifest" where arguments.count == 2:
            let manifest = try JSONDecoder().decode(
                EcosystemReleaseManifest.self,
                from: Data(contentsOf: URL(fileURLWithPath: arguments[1])))
            print("Verified release \(manifest.releaseID): \(manifest.components.count) components, \(manifest.contracts.count) contracts")
        case "release-dependencies" where arguments.count >= 2:
            do {
                let findings = try arguments.dropFirst().flatMap(localDependencies)
                if !findings.isEmpty { throw ReportCLIError.budgetFailure(findings) }
            } catch {
                FileHandle.standardError.write(Data("\(error)\n".utf8))
                exit(1)
            }
            print("Package dumps contain no local dependencies")
        default:
            throw ReportCLIError.usage
        }
    }

    private static func localDependencies(_ path: String) throws -> [String] {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let package = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = package["name"] as? String,
              let dependencies = package["dependencies"] as? [[String: Any]] else {
            throw ReportCLIError.invalidPackageDump(path)
        }
        return dependencies.flatMap { dependency -> [String] in
            if let local = dependency["fileSystem"] as? [[String: Any]] {
                return local.map { "\(name): local path dependency \($0["identity"] ?? "unknown")" }
            }
            let entries = dependency["sourceControl"] as? [[String: Any]] ?? []
            return entries.compactMap { entry in
                let location = entry["location"] as? [String: Any]
                let remotes = location?["remote"] as? [[String: String]] ?? []
                let usesFileURL = remotes.contains {
                    guard let url = $0["urlString"] else { return false }
                    return URL(string: url)?.isFileURL == true
                }
                guard location?["local"] != nil || usesFileURL else { return nil }
                return "\(name): local Git dependency \(entry["identity"] ?? "unknown")"
            }
        }
    }

    private static func loadReport(_ path: String) throws
        -> IncrementalMeasurementReport {
        try IncrementalMeasurementReport.decode(
            Data(contentsOf: URL(fileURLWithPath: path)))
    }
}
