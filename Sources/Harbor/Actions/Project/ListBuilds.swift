import BrightFutures

extension Project {
  public final class ListBuilds {
    // MARK: Output
    public typealias Payload
      = Future<Project, Failure>

    public enum Failure: Error {
      case fetchBuilds(Error)
    }

    // MARK: Action
    func call(for project: Project, inOrganization organization: Organization) -> Payload {
      return CodeshipFetchBuilds()
        .call(for: organization, project: project)
        .mapError(Failure.fetchBuilds)
        .map { response in
          project.setJsonBuilds(response.builds)
          return project
        }
    }
  }
}