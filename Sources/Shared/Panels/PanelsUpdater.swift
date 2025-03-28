import Foundation
import GRDB
import PromiseKit
import UIKit

public protocol PanelsUpdaterProtocol {
    func update()
}

final class PanelsUpdater: PanelsUpdaterProtocol {
    static var shared = PanelsUpdater()

    private var tokens: [(promise: Promise<HAPanels>, cancel: () -> Void)?] = []
    private var lastUpdate: Date?

    private var inForeground = true

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    public func update() {
        if let lastUpdate, lastUpdate.timeIntervalSinceNow > -5 {
            Current.Log.verbose("Skipping panels update, last update was \(lastUpdate)")
            return
        } else {
            lastUpdate = Date()
        }
        tokens.forEach({ $0?.cancel() })
        tokens = []

        Current.Log.verbose("Updating panels, servers count \(Current.servers.all.count)")
        for server in Current.servers.all {
            let request = Current.api(for: server)?.connection.send(.panels())
            tokens.append(request)

            request?.promise.done({ [weak self] panels in
                self?.saveInDatabase(panels, server: server)
            }).cauterize()
        }
    }

    @objc private func enterBackground() {
        tokens.forEach({ $0?.cancel() })
        tokens = []
    }

    private func saveInDatabase(_ panels: HAPanels, server: Server) {
        let appPanels = panels.allPanels.map { panel in
            AppPanel(
                serverId: server.identifier.rawValue,
                icon: panel.icon,
                title: panel.title,
                path: panel.path,
                component: panel.component,
                showInSidebar: panel.showInSidebar
            )
        }

        do {
            try Current.database().write { db in
                try AppPanel.filter(Column(DatabaseTables.AppPanel.serverId.rawValue) == server.identifier.rawValue)
                    .deleteAll(db)
                for panel in appPanels {
                    try panel.save(db)
                }
            }
        } catch {
            Current.Log.error("Error saving panels in database: \(error)")
        }
    }
}
