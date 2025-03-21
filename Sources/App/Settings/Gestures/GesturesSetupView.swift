import Shared
import SwiftUI

struct GesturesSetupView: View {
    @StateObject private var viewModel = GesturesSetupViewModel()
    @State private var swipeRightState = HAGestureAction.showSidebar
    var body: some View {
        List {
            AppleLikeListTopRowHeader(
                image: AnyView(Image(uiImage: MaterialDesignIcons.gestureIcon.image(
                    ofSize: .init(width: 80, height: 80),
                    color: Asset.Colors.haPrimary.color
                ))),
                title: L10n.Gestures.Screen.title,
                subtitle: L10n.Gestures.Screen.body
            )
            Section {
                ForEach(
                    AppGesture.allCases.sorted(by: { $0.setupScreenOrder < $1.setupScreenOrder }),
                    id: \.self
                ) { gesture in
                    Picker(gesture.localizedString, selection: .init(get: {
                        viewModel.selection(for: gesture)
                    }, set: { newValue in
                        viewModel.setSelection(for: gesture, newValue: newValue)
                    })) {
                        ForEach(HAGestureAction.allCases, id: \.self) { action in
                            makeRow(gestureAction: action)
                        }
                    }
                    .modify({ view in
                        if #available(iOS 16.0, *) {
                            view.pickerStyle(.navigationLink)
                        } else {
                            view.pickerStyle(.menu)
                        }
                    })
                }
            }
        }
    }

    private func makeRow(gestureAction: HAGestureAction) -> some View {
        Text(gestureAction.localizedString).tag(gestureAction)
    }
}

#Preview {
    NavigationView {
        GesturesSetupView()
    }
}
