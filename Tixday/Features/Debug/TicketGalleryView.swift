#if DEBUG
import SwiftUI

/// Every ticket design at widget sizes, for reviewing artwork. Launch with `-ticketGallery`.
struct TicketGalleryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(TicketSnapshot.samples()) { ticket in
                    Text(ticket.kind.name)
                        .font(Theme.eyebrow)
                        .foregroundStyle(.secondary)
                    // Real widget sizes on a 6.3" iPhone: small 158×158, medium 338×158.
                    TicketView(ticket: ticket, size: .small, notchColor: nil)
                        .frame(width: 158, height: 158)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    TicketView(ticket: ticket, size: .medium, notchColor: nil)
                        .frame(width: 338, height: 158)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
            .padding(12)
        }
        .background(Theme.canvas)
    }
}
#endif
