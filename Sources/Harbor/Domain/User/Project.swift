public final class Project: Codable {
  let id: String
  private(set) var name:   String = ""
  private(set) var url:    String = ""
  private(set) var builds: [Build] = []

  init(_ id: String) {
    self.id = id
  }

  var status: Status {
    return builds.last?.status ?? .unknown
  }
}

extension Project: CustomStringConvertible {
  public var description: String {
    return name
  }
}

extension Project {
  typealias Json = FetchProjects.Response.Project

  // MARK: json updates
  func setJson(_ json: Json) {
    name = json.name
    url  = json.repositoryUrl
  }

  func setJsonBuilds(_ json: [Build.Json]) {
    builds = Build.fromJson(json)
  }

  // MARK: json factories
  static func fromJson(_ json: Json) -> Project {
    let project = Project(json.uuid)
    project.setJson(json)
    return project
  }

  static func fromJson(_ json: [Json]) -> [Project] {
    return json.map { .fromJson($0) }
  }
}
