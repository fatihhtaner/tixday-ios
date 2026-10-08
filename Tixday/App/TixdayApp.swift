import SwiftData
import SwiftUI

@main
struct TixdayApp: App {
    private let container = SharedStore.makeContainer()

    init() {
        #if DEBUG
        // Fills an empty store with one ticket of each kind, for screenshots and design review.
        if CommandLine.arguments.contains("-sampleData") {
            let context = container.mainContext
            if ((try? context.fetchCount(FetchDescriptor<TicketEvent>())) ?? 0) == 0 {
                for sample in TicketSnapshot.samples() {
                    let event = TicketEvent(
                        title: sample.title, date: sample.date, kind: sample.kind, headline: sample.headline,
                        origin: sample.origin, destination: sample.destination,
                        stubLeft: sample.stubLeft, stubRight: sample.stubRight
                    )
                    event.createdAt = sample.createdAt
                    context.insert(event)
                }
                try? context.save()
            }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            TicketListView()
        }
        .modelContainer(container)
    }
}
