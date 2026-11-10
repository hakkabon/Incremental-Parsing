public enum EcosystemReleaseLayer: Int, Codable, CaseIterable, Sendable {
    case foundation
    case engine
    case tooling
    case language
    case product
}

public enum EcosystemReleaseMaturity: String, Codable, Sendable {
    case stable
    case experimental
}

public struct EcosystemReleaseComponent: Hashable, Codable, Sendable {
    public let name: String
    public let swiftPMIdentity: String
    public let minimumVersion: String
    public let layer: EcosystemReleaseLayer
    public let maturity: EcosystemReleaseMaturity
    public let dependencies: [String]

    public init(
        name: String, swiftPMIdentity: String, minimumVersion: String,
        layer: EcosystemReleaseLayer, maturity: EcosystemReleaseMaturity,
        dependencies: [String] = []
    ) {
        self.name = name
        self.swiftPMIdentity = swiftPMIdentity
        self.minimumVersion = minimumVersion
        self.layer = layer
        self.maturity = maturity
        self.dependencies = dependencies
    }
}

public struct EcosystemReleaseContract: Hashable, Codable, Sendable {
    public let id: String
    public let owner: String
    public let schemaVersion: Int

    public init(id: String, owner: String, schemaVersion: Int) {
        self.id = id; self.owner = owner; self.schemaVersion = schemaVersion
    }
}

public enum EcosystemReleaseManifestError: Error, Equatable, Sendable {
    case unsupportedSchema(Int)
    case invalidReleaseID
    case invalidComponent(String)
    case invalidVersion(component: String, version: String)
    case duplicateComponent(String)
    case duplicateIdentity(String)
    case missingDependency(component: String, dependency: String)
    case upwardDependency(component: String, dependency: String)
    case dependencyCycle([String])
    case invalidContract(String)
    case missingContractOwner(contract: String, owner: String)
}

/// Machine-readable compatibility envelope for one coordinated ecosystem
/// release. It records compatibility floors and ownership; exact source
/// revisions remain the responsibility of the downstream release lockfile.
public struct EcosystemReleaseManifest: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let releaseID: String
    public let swiftToolsVersion: String
    public let components: [EcosystemReleaseComponent]
    public let contracts: [EcosystemReleaseContract]

    public init(
        releaseID: String, swiftToolsVersion: String,
        components: [EcosystemReleaseComponent],
        contracts: [EcosystemReleaseContract]
    ) throws {
        schemaVersion = Self.currentSchemaVersion
        self.releaseID = releaseID
        self.swiftToolsVersion = swiftToolsVersion
        self.components = components
        self.contracts = contracts
        try validate()
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        releaseID = try values.decode(String.self, forKey: .releaseID)
        swiftToolsVersion = try values.decode(String.self, forKey: .swiftToolsVersion)
        components = try values.decode([EcosystemReleaseComponent].self, forKey: .components)
        contracts = try values.decode([EcosystemReleaseContract].self, forKey: .contracts)
        try validate()
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw EcosystemReleaseManifestError.unsupportedSchema(schemaVersion)
        }
        guard Self.isIdentifier(releaseID), Self.isToolsVersion(swiftToolsVersion) else {
            throw EcosystemReleaseManifestError.invalidReleaseID
        }
        var byName: [String: EcosystemReleaseComponent] = [:]
        var identities = Set<String>()
        for component in components {
            guard Self.isName(component.name), Self.isIdentity(component.swiftPMIdentity) else {
                throw EcosystemReleaseManifestError.invalidComponent(component.name)
            }
            guard Self.isSemanticVersion(component.minimumVersion) else {
                throw EcosystemReleaseManifestError.invalidVersion(
                    component: component.name, version: component.minimumVersion)
            }
            guard byName.updateValue(component, forKey: component.name) == nil else {
                throw EcosystemReleaseManifestError.duplicateComponent(component.name)
            }
            guard identities.insert(component.swiftPMIdentity.lowercased()).inserted else {
                throw EcosystemReleaseManifestError.duplicateIdentity(component.swiftPMIdentity)
            }
            guard Set(component.dependencies).count == component.dependencies.count else {
                throw EcosystemReleaseManifestError.invalidComponent(component.name)
            }
        }
        for component in components {
            for dependencyName in component.dependencies {
                guard let dependency = byName[dependencyName] else {
                    throw EcosystemReleaseManifestError.missingDependency(
                        component: component.name, dependency: dependencyName)
                }
                guard dependency.layer.rawValue <= component.layer.rawValue else {
                    throw EcosystemReleaseManifestError.upwardDependency(
                        component: component.name, dependency: dependencyName)
                }
            }
        }
        var visiting = Set<String>(), visited = Set<String>()
        func visit(_ name: String, path: [String]) throws {
            if visited.contains(name) { return }
            if visiting.contains(name) {
                throw EcosystemReleaseManifestError.dependencyCycle(path + [name])
            }
            visiting.insert(name)
            for dependency in byName[name]?.dependencies ?? [] {
                try visit(dependency, path: path + [name])
            }
            visiting.remove(name); visited.insert(name)
        }
        for name in byName.keys.sorted() { try visit(name, path: []) }

        var contractIDs = Set<String>()
        for contract in contracts {
            guard Self.isIdentifier(contract.id), contract.schemaVersion > 0,
                  contractIDs.insert(contract.id).inserted else {
                throw EcosystemReleaseManifestError.invalidContract(contract.id)
            }
            guard byName[contract.owner] != nil else {
                throw EcosystemReleaseManifestError.missingContractOwner(
                    contract: contract.id, owner: contract.owner)
            }
        }
    }

    private static func isSemanticVersion(_ value: String) -> Bool {
        let pieces = value.split(separator: ".", omittingEmptySubsequences: false)
        return pieces.count == 3 && pieces.allSatisfy {
            !$0.isEmpty && $0.allSatisfy(\.isNumber)
        }
    }

    private static func isToolsVersion(_ value: String) -> Bool {
        let pieces = value.split(separator: ".", omittingEmptySubsequences: false)
        return pieces.count == 2 && pieces.allSatisfy {
            !$0.isEmpty && $0.allSatisfy(\.isNumber)
        }
    }

    private static func isName(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" }
    }

    private static func isIdentity(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy {
            $0.isLowercase || $0.isNumber || $0 == "-"
        }
    }

    private static func isIdentifier(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy {
            $0.isLowercase || $0.isNumber || $0 == "-" || $0 == "."
        }
    }
}
