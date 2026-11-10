import Foundation
import IncrementalParsing

private enum ReportCLIError: Error, CustomStringConvertible {
    case usage
    case evidenceMismatch([String])
    case budgetFailure([String])

    var description: String {
        switch self {
        case .usage:
            return """
            Usage:
              incremental-report verify REPORT.json
              incremental-report compare REPORT.json REPORT.json [REPORT.json ...]
              incremental-report gate REPORT.json BUDGETS.json
              incremental-report release-manifest MANIFEST.json
            """
        case .evidenceMismatch(let paths):
            return "Evidence fingerprints differ: \(paths.joined(separator: ", "))"
        case .budgetFailure(let violations):
            return violations.joined(separator: "\n")
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
        default:
            throw ReportCLIError.usage
        }
    }

    private static func loadReport(_ path: String) throws
        -> IncrementalMeasurementReport {
        try IncrementalMeasurementReport.decode(
            Data(contentsOf: URL(fileURLWithPath: path)))
    }
}
