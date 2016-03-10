import Cocoa

struct BuildViewModel {
  let build: Build
  let projectId: Int

  init(build: Build, projectId: Int) {
    self.build = build
    self.projectId = projectId
  }

  //
  // MARK: display
  //

  var message: String {
    get { return self.build.message != nil ? self.build.message! : "Unknown" }
  }

  var buildUrl: String {
    get { return "https://codeship.com/projects/\(projectId)/builds/\(build.id!)" }
  }

  func authorshipInformation() -> String {
    let dateString = self.dateString()

    if let name = self.build.gitHubUsername {
      return "By \(name) at \(dateString)"
    } else {
      return "Started at \(dateString)"
    }
  }

  private func dateString() -> String {
    guard let date = self.build.startedAt else {
      return "Unknown Date"
    }

    // TODO: date formatters are expensive (on iOS at least) so it might be worth
    // caching this
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "MM/dd/YY 'at' hh:mm a"
    return dateFormatter.stringFromDate(date)
  }

  //
  // MARK: Actions
  //

  func openBuildUrl() {
    let buildURL  = NSURL(string: self.buildUrl)!
    let workspace = NSWorkspace.sharedWorkspace()

    workspace.openURL(buildURL)
  }
}