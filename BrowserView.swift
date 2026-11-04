
import SwiftUI
import WebKit

struct BrowserTab: Identifiable {
    let id = UUID()
    var title: String
    var url: URL
}

struct BrowserView: View {
    @State private var address = "https://www.google.com"
    @State private var tabs: [BrowserTab] = [
        BrowserTab(
            title: "Google",
            url: URL(string: "https://www.google.com")!
        )
    ]

    @State private var selectedTabID: UUID?
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var showTabs = false

    private let webView = WKWebView()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(.cyan)

                TextField("Adres veya ara", text: $address)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit { navigate() }

                Button(action: navigate) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.cyan)
                        .font(.title2)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(10)

            BrowserWebView(
                webView: webView,
                onStateChange: { title, url, back, forward in
                    canGoBack = back
                    canGoForward = forward

                    if let url {
                        address = url.absoluteString
                    }

                    if let title {
                        updateCurrentTab(title: title, url: url)
                    }
                }
            )

            HStack {
                Button {
                    webView.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canGoBack)

                Spacer()

                Button {
                    webView.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canGoForward)

                Spacer()

                Button {
                    webView.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

                Spacer()

                Button {
                    addTab()
                } label: {
                    Image(systemName: "plus")
                }

                Spacer()

                Button {
                    showTabs = true
                } label: {
                    Image(systemName: "square.on.square")
                }
                .confirmationDialog(
                    "Sekmeler",
                    isPresented: $showTabs,
                    titleVisibility: .visible
                ) {
                    ForEach(tabs) { tab in
                        Button(tab.title) {
                            load(tab)
                        }
                    }

                    Button("Yeni sekme") {
                        addTab()
                    }

                    Button("Geçerli sekmeyi kapat", role: .destructive) {
                        closeCurrentTab()
                    }

                    Button("Vazgeç", role: .cancel) {}
                }
            }
            .font(.system(size: 19))
            .padding(16)
            .background(.ultraThinMaterial)
        }
        .background(Color.black)
        .onAppear {
            selectedTabID = tabs.first?.id
            webView.load(
                URLRequest(url: tabs[0].url)
            )
        }
    }

    private func navigate() {
        let input = address.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !input.isEmpty else { return }

        let url: URL?

        if input.contains(" ") ||
            (!input.contains(".") && !input.contains("://")) {
            let query = input.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ) ?? input

            url = URL(
                string: "https://www.google.com/search?q=\(query)"
            )
        } else {
            let candidate = input.contains("://")
                ? input
                : "https://" + input

            url = URL(string: candidate)
        }

        guard let finalURL = url,
              ["http", "https"].contains(finalURL.scheme?.lowercased() ?? "")
        else { return }

        address = finalURL.absoluteString
        webView.load(URLRequest(url: finalURL))

        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func addTab() {
        let tab = BrowserTab(
            title: "Yeni sekme",
            url: URL(string: "https://www.google.com")!
        )

        tabs.append(tab)
        load(tab)
    }

    private func load(_ tab: BrowserTab) {
        selectedTabID = tab.id
        address = tab.url.absoluteString
        webView.load(URLRequest(url: tab.url))
    }

    private func closeCurrentTab() {
        guard tabs.count > 1 else { return }

        let index = tabs.firstIndex {
            $0.id == selectedTabID
        } ?? 0

        tabs.remove(at: index)

        let next = tabs[min(index, tabs.count - 1)]
        load(next)
    }

    private func updateCurrentTab(title: String, url: URL?) {
        guard let index = tabs.firstIndex(
            where: { $0.id == selectedTabID }
        ) else { return }

        tabs[index].title = title

        if let url {
            tabs[index].url = url
        }
    }
}

struct BrowserWebView: UIViewRepresentable {
    let webView: WKWebView

    let onStateChange: (
        String?, URL?, Bool, Bool
    ) -> Void

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator

        webView.allowsBackForwardNavigationGestures = true

        webView.configuration.allowsInlineMediaPlayback = true

        webView.configuration.mediaTypesRequiringUserActionForPlayback = []

        return webView
    }

    func updateUIView(
        _ uiView: WKWebView,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onStateChange: onStateChange)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onStateChange: (
            String?, URL?, Bool, Bool
        ) -> Void

        init(
            onStateChange: @escaping (
                String?, URL?, Bool, Bool
            ) -> Void
        ) {
            self.onStateChange = onStateChange
        }

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            onStateChange(
                webView.title,
                webView.url,
                webView.canGoBack,
                webView.canGoForward
            )
        }

        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation!
        ) {
            onStateChange(
                webView.title,
                webView.url,
                webView.canGoBack,
                webView.canGoForward
            )
        }
    }
}
