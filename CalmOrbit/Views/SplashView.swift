import SwiftUI
import Combine
import Network

struct SplashView: View {
    @Environment(\.palette) private var p
    
    @StateObject private var deck = FlightDeck()
    
    @State private var isVisible = true
    @State private var bgIn = false
    @State private var orbIn = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var pulse = false
    @State private var titleIn = false
    @State private var orbit = false
    @State private var networkMonitor = NWPathMonitor()
    @State private var exit = false
    @State private var coordinator: Timer?

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Layer 1 — shifting background gradient
                    LinearGradient(colors: [p.bgDeep, p.bg, p.bgSoft],
                                   startPoint: bgIn ? .topLeading : .top,
                                   endPoint: bgIn ? .bottomTrailing : .bottom)
                        .ignoresSafeArea()
                        .opacity(bgIn ? 1 : 0.4)
                    
                    Image("loading_splash_image")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                        .opacity(0.5)
                        .blur(radius: 1)
                    
                    NavigationLink(
                        destination: CupolaView().navigationBarHidden(true),
                        isActive: $deck.navigateToWeb
                    ) { EmptyView() }

                    // Layer 2 — midground drifting bubbles + orbiting dots
                    BubblesBackground(count: 16, isActive: isVisible)
                        .opacity(bgIn ? 1 : 0)

                    ZStack {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(p.cyan.opacity(0.5))
                                .frame(width: 10, height: 10)
                                .offset(y: -130)
                                .rotationEffect(.degrees((orbit ? 360 : 0) + Double(i) * 120))
                                .opacity(orbIn ? 0.8 : 0)
                        }
                    }
                    .scaleEffect(exit ? 1.6 : 1)
                    
                    NavigationLink(
                        destination: RootView().navigationBarBackButtonHidden(true),
                        isActive: $deck.navigateToMain
                    ) { EmptyView() }

                    // Layer 3 — foreground orb + title
                    VStack(spacing: 26) {
                        OrbView(scale: orbIn ? (pulse ? 1.06 : 0.98) : 0.2,
                                intensity: orbIn ? 1 : 0.2,
                                size: 190)
                            .scaleEffect(exit ? 2.4 : 1)
                            .opacity(exit ? 0 : 1)

                        VStack(spacing: 8) {
                            Text("Calm Orbit +")
                                .font(AppFont.rounded(34, .bold))
                                .foregroundColor(p.textPrimary)
                        }
                        .opacity(titleIn && !exit ? 1 : 0)
                        .offset(y: titleIn ? 0 : 18)
                        .scaleEffect(exit ? 1.1 : 1)
                    }
                    .offset(y: -10)
                }
                .onAppear { liftoff() }
                .fullScreenCover(isPresented: $deck.showPermissionPrompt) {
                    ConsentBay(deck: deck)
                }
                .fullScreenCover(isPresented: $deck.showOfflineView) {
                    DriftBay()
                }
                .onDisappear { teardown() }
            }
            .ignoresSafeArea()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func liftoff() {
        wireStreams()
        wireNetworkMonitoring()
        deck.ignite()
        startSequence()
    }

    private func startSequence() {
        isVisible = true
        withAnimation(.easeOut(duration: 0.6)) { bgIn = true }

        var step = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { t in
            step += 1
            switch step {
            case 1: // ~0.75s — Stage 2: orb + orbiting dots appear
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    orbIn = true
                }
                withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                    orbit = true
                }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            case 2: // ~1.5s — Stage 3: title spring entrance
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    titleIn = true
                }
            default:
                break
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        coordinator = timer
    }
    
    private func wireStreams() {
        NotificationCenter.default.publisher(for: .lockArrived)
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                deck.ingestLock(data)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .echoesArrived)
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                deck.ingestEchoes(data)
            }
            .store(in: &cancellables)
    }

    private func teardown() {
        isVisible = false
        pulse = false
        orbit = false
        coordinator?.invalidate()
        coordinator = nil
    }
    
    private func wireNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                deck.networkConnectivityChanged(path.status == .satisfied)
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
    
}

#Preview {
    SplashView()
}


struct ConsentBay: View {
    let deck: FlightDeck

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image("calms")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.9)

                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    horView
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var horView: some View {
        HStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                titleText
                subtitleText
            }
            
            Spacer()
            
            VStack {
                Spacer()
                actionButtons
            }
            
            Spacer()
        }
        .padding(.bottom, 24)
    }

    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.system(size: 22, weight: .black, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                deck.acceptConsent()
            } label: {
                Image("calmess")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            skipes
        }
        .padding(.horizontal, 12)
    }
    
    private var skipes: some View {
        Button {
            deck.skipConsent()
        } label: {
            Image("skipes")
                .resizable()
                .frame(width: 275, height: 36)
        }
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.system(size: 14, weight: .heavy, design: .monospaced))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
}

struct DriftBay: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("loading_error_image")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .opacity(0.9)
                    .blur(radius: 3)
                
                errorView
            }
        }
        .ignoresSafeArea()
    }
    
    private var errorView: some View {
        Image("loading_error")
            .resizable()
            .frame(width: 300, height: 190)
    }
    
}
