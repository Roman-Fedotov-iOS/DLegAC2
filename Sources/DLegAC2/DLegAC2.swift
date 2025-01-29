import SwiftUI
import ApphudSDK
import StoreKit
import WebKit

public enum AppConfiguration {
    public static let termsUrl = URL(string: "https://sites.google.com/view/auto-clicker-tu")
    public static let privacyUrl = URL(string: "https://sites.google.com/view/auto-clicker-pp")
    public static let contactUsUrl = URL(string: "mailto:claytonreed732@outlook.com")
}

public final class PaywallsManager {
    static let shared = PaywallsManager()

    typealias ProductClosure = (ApphudProduct) -> Void

    private var subscribers = [ProductClosure]()

    private var products: [ApphudProduct]?

    private var product: ApphudProduct? {
        return products?.first
    }

    func subscribe(callback: @escaping ProductClosure) {
        if let product {
            callback(product)
        } else {
            subscribers.append(callback)
            
            Apphud.paywallsDidLoadCallback { [weak self] paywalls in
                if let paywall = paywalls.first(where: { $0.identifier == (UserDefaults.standard.bool(forKey: "finishedOnboarding") ? "inapp_paywall" : "onboarding_paywall") }) {
                    self?.products = paywall.products
                    self?.notifySubscribers()
                }
            }
        }
    }

    private func notifySubscribers() {
        if let product {
            subscribers.forEach { callback in
                callback(product)
            }

            subscribers.removeAll()
        }
    }
}

public struct PreloaderView: View {
    
    private let titleText = "Auto Clicker & Tapper"
    private let titleSize: CGFloat = 32
    
    @State private var rotationAngle: Double = 0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
           
            VStack(spacing: 16) {
                Image("PreloaderIcon")
                    .resizable()
                    .frame(width: 200, height: 200)
                
                Text(titleText)
                    .font(.system(size: titleSize))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
            .offset(y: -50)
            
            CircleSnakeLoader()
                .frame(width: 40, height: 40)
                .offset(y: UIScreen.main.bounds.height / 2 - 80)
        }
        .onAppear {
            startRotation()
        }
    }
    
    private func startRotation() {
        withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

public struct CircleSnakeLoader: View {
    @State private var rotationAngle: Double = 0
    
    public var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .foregroundColor(.blue)
            .frame(width: 40, height: 40)
            .rotationEffect(.degrees(rotationAngle))
            .onAppear {
                withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
    }
}

public struct BackgroundView: View {

    public var body: some View {
        Image("PaywallBackground")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

public struct BigSmallTextView: View {
    var productDescription: String
    
    public var body: some View {
        VStack {
            Text("Unlock Full Access\n to all the features")
                .font(.system(size: 30))
                .bold()
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
            
            Text(productDescription)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.bottom, 18)
        }
    }
}

public struct ExitButtonView: View {
    let exitButtonAction: () -> Void
    
    public var body: some View {
        HStack {
            Button(action: exitButtonAction) {
                Text("✕")
                    .font(.system(size: 20).bold())
                    .foregroundColor(.gray)
                    .padding()
            }
            Spacer()
        }
    }
}

public struct FooterButtonsView: View {
    @Environment(\.openURL) var openUrl

    var restoreAction: () -> Void

    public var body: some View {
        HStack(alignment: .center, spacing: 30) {
            Button(action: termsButtonAction) {
                Text("Terms of Use")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)
            }
            Button(action: privacyButtonAction) {
                Text("Restore")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)
            }
            Button(action: restoreButtonAction) {
                Text("Privacy Policy")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray)
            }
        }
        .frame(height: 20)
        .padding(.vertical, 5)
    }
    
    private func termsButtonAction() {
        if let url = AppConfiguration.termsUrl {
            openUrl(url)
        }
    }
    
    private func privacyButtonAction() {
        restoreAction()
    }
    
    private func restoreButtonAction() {
        if let url = AppConfiguration.privacyUrl {
            openUrl(url)
        }
    }
}

public struct SubscribeButtonView: View {
    var freeTrialToggle: Bool
    @Binding var isScaleContinue: Bool

    var onSubscribe: () -> Void

    public var body: some View {
        Button(action: subscribeButtonAction) {
            Image("ContinueButton")
                .resizable()
                .frame(height: 70)
                .scaleEffect(isScaleContinue ? 0.95 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                    value: isScaleContinue
                )
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                generateHapticFeedback()
            }
        )
    }
    
    private func subscribeButtonAction() {
        onSubscribe()
    }
    
    private func generateHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

public struct PayWallView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dismiss) private var dismiss

    @State private var isScaleContinue = false
    @State private var freeTrialToggle = false

    @State private var apphudProducts: [ApphudProduct] = []

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var fromOnboard: Bool
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
    
    public var body: some View {
        ZStack {
            BackgroundView()
            VStack {
                ExitButtonView(exitButtonAction: exitButtonAction)
                Spacer()
                BigSmallTextView(productDescription: productDescription)
                SubscribeButtonView(freeTrialToggle: freeTrialToggle, isScaleContinue: $isScaleContinue) {
                    if !apphudProducts.isEmpty {
                        Apphud.purchase(apphudProducts[0]) { result in
                            if result.success {
                                UserDefaults().set(true, forKey: "finishedOnboarding")
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    if let window = windowScene.windows.first {
                                        window.rootViewController = UIHostingController(rootView: MainTabBarView())
                                        window.makeKeyAndVisible()
                                    }
                                }
                            }
                        }
                    } else {
                        showAlert(title: "Error", message: "Products not loaded yet.")
                    }
                }
                FooterButtonsView() {
                    onRestore()
                }
            }
            .padding(EdgeInsets(top: UIScreen.main.bounds.height < 700 ? 80 : 30, leading: 16, bottom: UIScreen.main.bounds.height < 700 ? 85 : 50, trailing: 16))
            .onAppear {
                impactFeedback.prepare()
                startScalingEffect()
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            Apphud.paywallsDidLoadCallback { paywalls in
                if let paywall = paywalls.first(where: { $0.identifier == (!UserDefaults.standard.bool(forKey: "finishedOnboarding") ? "onboarding_paywall" : "inapp_paywall") }) {
                    apphudProducts = paywall.products
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func startScalingEffect() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            isScaleContinue = true
        }
    }
    
    private func exitButtonAction() {
        if fromOnboard {
            UserDefaults().set(true, forKey: "finishedOnboarding")
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: MainTabBarView())
                    window.makeKeyAndVisible()
                }
            }
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func onRestore() {
        Apphud.restorePurchases { result1, result2, error in
            DispatchQueue.main.async {
                if let error {
                    showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    showAlert(title: "Restored", message: "Purchases restored successfully.")
                }
            }
        }
    }

    private var productDescription: String {
        
        if apphudProducts.isEmpty {
            return "loading products..."
        } else {
            if apphudProducts[0].productId.contains("trial") {
                return "Start to continue App \nwith a 3-day trial and \(String(format: "$%.02f", apphudProducts[0].skProduct!.price.doubleValue)) per week"
            } else {
                return "Start to continue App \nfor \(String(format: "$%.02f", apphudProducts[0].skProduct!.price.doubleValue)) per week"
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showAlert = true
    }
}

public struct BaseOnboardView: View {
    
    @State private var isScaleContinue = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
    private let backgroundImage: String
    private let bigText: String
    private let smallText: String
    private let nextView: AnyView
    
    private let bigTextFontSize: CGFloat = 30
    private let smallTextFontSize: CGFloat = 16

    init(backgroundImage: String, bigText: String, smallText: String, nextView: AnyView) {
        self.backgroundImage = backgroundImage
        self.bigText = bigText
        self.smallText = smallText
        self.nextView = nextView
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Image(backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    Text(bigText)
                        .font(.system(size: bigTextFontSize))
                        .bold()
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 12)
                    
                    Text(smallText)
                        .font(.system(size: smallTextFontSize))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 18)
                    
                    NavigationLink(destination: nextView) {
                        Image("ContinueButton")
                            .resizable()
                            .frame(height: 70)
                            .scaleEffect(isScaleContinue ? 0.95 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                value: isScaleContinue
                            )
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now()) {
                                    isScaleContinue = true
                                }
                            }
                    }
                    
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            generateHapticFeedback()
                        }
                    )
                }
                .padding(EdgeInsets(top: 0, leading: 16, bottom: UIScreen.main.bounds.height < 700 ? 120 : 70, trailing: 16))
                .onAppear {
                    impactFeedback.prepare()
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private func generateHapticFeedback() {
        impactFeedback.impactOccurred()
    }
}

public struct Onboard1View: View {
    
    public init() {}
    
    public var body: some View {
        BaseOnboardView(
            backgroundImage: "Onboard1Background",
            bigText: " Save time with\n Auto Clicker",
            smallText: " Economize hours while interner\n scrolling and tapping",
            nextView: AnyView(Onboard2View())
        )
    }
}

public struct Onboard2View: View {
    public var body: some View {
        BaseOnboardView(
            backgroundImage: "Onboard2Background",
            bigText: " User-friendly\n installation",
            smallText: " Easy to use interface with\n adjustable settings",
            nextView: AnyView(Onboard3View())
        )
    }
}

public struct Onboard3View: View {
    public var body: some View {
        BaseOnboardView(
            backgroundImage: "Onboard3Background",
            bigText: " Get more\n productivity",
            smallText: " Make your digital interactions\n more efficient and simple",
            nextView: AnyView(PayWallView(fromOnboard: true))
        )
    }
}

public struct DetailSettingsView: View {
    let text: String
    
    public var body: some View {
        ZStack {
            
            Image("MainTabBarBackground")
                .resizable()
                .ignoresSafeArea()
            
            Text(text)
                .foregroundColor(.black)
        }
    }
}

public enum SettingItem: Int, Identifiable, CaseIterable {
    case rateApp
    case contactUs
    case privacyPolicy
    case termsOfService

    public var id: Int {
        return rawValue
    }

    var title: String {
        return switch self {
        case .rateApp: "Rate Our App"
        case .contactUs: "Contact Us"
        case .privacyPolicy: "Privacy Policy"
        case .termsOfService: "Terms of Service"
        }
    }

    public var image: String {
        return switch self {
        case .rateApp: "RateOurAppImage"
        case .contactUs: "ContactUsImage"
        case .privacyPolicy: "PrivacyPolicyImage"
        case .termsOfService: "TermsOfServiceImage"
        }
    }
}

public struct SettingItemView: View {
    let settingItem: SettingItem
    let action: (SettingItem) -> Void

    public var body: some View {
        Button {
            action(settingItem)
        } label: {
            HStack(spacing: 13) {
                Image(settingItem.image)
                Text(settingItem.title)
                    .foregroundColor(.black)
                Spacer()
                Image("ArrowImage")
            }
            .padding(.horizontal, 20)
            .frame(height: 65)
        }
    }
}

public struct SettingsView: View {
    @Environment(\.openURL) var openUrl

    @State private var showsProPlanButton = true
    @State private var isPresentedPayWall = false
    @State private var selectedSettingItem: SettingItem?

    public var body: some View {
        NavigationView {
            ZStack {
                Image("MainTabBarBackground")
                    .resizable()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ForEach(SettingItem.allCases, id: \.id) { settingItem in
                        SettingItemView(settingItem: settingItem) { settingItem in
                            selectedSettingItem = settingItem
                        }
                    }

                    if showsProPlanButton {
                        Button {
                            isPresentedPayWall = true
                        } label: {
                            Image("SettingsUpgradeButton")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 27)
                        .fullScreenCover(isPresented: $isPresentedPayWall) {
                            PayWallView(fromOnboard: false)
                        }
                    }

                    Spacer()
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .offset(y: 38)
            }
        }
        .onChange(of: selectedSettingItem) { settingItem in
            switch settingItem {
            case .rateApp:
                let scene = UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene

                if let scene {
                    DispatchQueue.main.async {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            case .contactUs:
                if let url = AppConfiguration.contactUsUrl {
                    openUrl(url)
                }
            case .privacyPolicy:
                if let url = AppConfiguration.privacyUrl {
                    openUrl(url)
                }
            case .termsOfService:
                if let url = AppConfiguration.termsUrl {
                    openUrl(url)
                }
            case nil:
                break
            }
        }
        .task {
            let purchased = await Wasdf.shared.wasdf()
            showsProPlanButton = purchased == nil
        }
    }
}

public class Wasdf: NSObject, ObservableObject {
    public static let shared = Wasdf()

    public func wasdf() async -> String? {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            return transaction.productID
        }
        return nil
    }
}

public struct MainTabBarView: View {
    
    @State private var selectedTabItem = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTabItem) {
            MyAppsView()
                .tabItem {
                    Image(selectedTabItem == 0 ? "MyAppsSelected" : "MyAppsDisSelected")
                }
                .tag(0)
            
            MySitesView()
                .tabItem {
                    Image(selectedTabItem == 1 ? "MySitesSelected" : "MySitesDisSelected")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(selectedTabItem == 2 ? "SetingsSelected" : "SettingsDisSelected")
                }
                .tag(2)
        }
    }
}

public struct MyAppsView: View {
    
    @State private var isPhotoPickerPresented = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedApp: AppItem?

    var appItems = [
        AppItem(imageName: "TIkTokImage", title: "TikTok", urlScheme: "tiktok://"),
        AppItem(imageName: "TelegramImage", title: "Telegram", urlScheme: "tg://"),
        AppItem(imageName: "InstagramImage", title: "Instagram", urlScheme: "instagram://"),
        AppItem(imageName: "XImage", title: "X", urlScheme: "twitter://"),
        AppItem(imageName: "TinderImage", title: "Tinder", urlScheme: "tinder://"),
        AppItem(imageName: "SpotifyImage", title: "Spotify", urlScheme: "spotify://"),
        AppItem(imageName: "MegogoImage", title: "Megogo", urlScheme: "megogo://"),
        AppItem(imageName: "TwitchImage", title: "Twitch", urlScheme: "twitch://"),
        AppItem(imageName: "YouTubeImage", title: "YouTube", urlScheme: "youtube://"),
    ]
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    public var body: some View {
        NavigationView {
            ZStack {
                Image("MainTabBarBackground")
                    .resizable()
                    .ignoresSafeArea()
                
                VStack {
                    Text("My apps")
                        .font(.system(size: 16))
                        .padding(.top, 30)
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(appItems) { item in
                                
                                Button(action: {
//                                    openApp(item: item)
//                                    if let url = URL(string: item.urlScheme), UIApplication.shared.canOpenURL(url) {
                                        
                                        selectedApp = item
                                        
//                                    } else {
//                                        alertMessage = "\(item.title) is not installed on your device."
//                                        showAlert = true
//                                    }
                                }
                                ) {
                                    VStack {
                                        Image(item.imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                        
                                        Text(item.title)
                                            .font(.caption)
                                            .foregroundColor(.black)
                                            .padding(.top, 8)
                                    }
                                    .frame(width: 100, height: 120)
                                    .background(Image("GridItemBackground"))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Auto Clicker")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $selectedApp) { appItem in
                SearchView(searchText: appItem.title)
            }
//            .alert(isPresented: $showAlert) {
//                Alert(title: Text("App Not Installed"),
//                      message: Text(alertMessage),
//                      dismissButton: .default(Text("OK")))
//            }
        }
    }
    
    //    private func openApp(item: AppItem) {
    //        if let url = URL(string: item.urlScheme), UIApplication.shared.canOpenURL(url) {
    //            UIApplication.shared.open(url)
    //        } else {
    //            alertMessage = "\(item.title) is not installed on your device."
    //            showAlert = true
    //        }
    //    }
    
}

public struct PlusButtonView: View {
    @Binding var isPresented: Bool
    
    public var body: some View {
        Button(action: {
            isPresented.toggle()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color("CustomBlue"))
                .clipShape(Circle())
                .shadow(color: Color("CustomBlue").opacity(0.7), radius: 5, x: 5, y: 5)
        }
        .padding(.bottom, 20)
        .padding(.trailing, 20)
    }
}

public struct AppItem: Identifiable  {
    public let id = UUID()
    var imageName: String
    var title: String
    var urlScheme: String
}

public struct MySitesView: View {
    
    @State private var sitesItems: [SitesItem] = []
    @State private var isSheetPresented = false
    @State private var newURL = ""
    @State private var newTitle = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedItem: SitesItem? = nil
    
    private let siteManager = SiteManager()
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    public var body: some View {
        NavigationView {
            ZStack {
                Image("MainTabBarBackground")
                    .resizable()
                    .ignoresSafeArea()
                
                VStack {
                    Text("My Sites")
                        .font(.system(size: 16))
                        .padding(.top, 30)
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 30) {
                            ForEach(sitesItems.indices, id: \.self) { index in
                                Button(action: {
                                    selectedItem = sitesItems[index]
                                }) {
                                    VStack {
                                        Image(sitesItems[index].imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                        
                                        Text(sitesItems[index].title)
                                            .font(.caption)
                                            .foregroundColor(.black)
                                            .padding(.top, 8)
                                    }
                                    .frame(width: 100, height: 120)
                                    .background(Image("GridItemBackground"))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                }
                                .contextMenu {
                                    Button(action: {
                                        siteManager.deleteSite(at: index, from: &sitesItems)
                                    }) {
                                        Text("Delete")
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                        .padding(.horizontal, 50)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        PlusButtonView(isPresented: $isSheetPresented)
                    }
                    .padding(.bottom, 20)
                    .padding(.trailing, 20)
                }
            }
            .navigationTitle("Auto Clicker")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                siteManager.initializeDefaultSites(to: &sitesItems)
            }
            .onDisappear {
                UserDefaultsService().saveSitesItems(sitesItems)
            }
            .sheet(isPresented: $isSheetPresented) {
                if #available(iOS 16.4, *) {
                    GeometryReader { _ in
                        VStack(spacing: 20) {
                            Text("Add Site")
                                .font(.headline)
                                .padding(.top, 58)
                            
                            TextField("Enter URL", text: $newURL)
                                .padding()
                                .background(Color("TextFieldBackground"))
                                .cornerRadius(30)
                                .padding(.horizontal)
                                .onChange(of: newURL) { newValue in
                                    if newValue == "https://www" {
                                        newURL = ""
                                    }
                                    if !newValue.hasPrefix("https://www") && !newValue.isEmpty {
                                        newURL = "https://www." + newValue
                                    }
                                }
                            
                            TextField("Enter Name", text: $newTitle)
                                .padding()
                                .background(Color("TextFieldBackground"))
                                .cornerRadius(30)
                                .padding(.horizontal)
                            
                            Button(action: {
                                guard !newTitle.isEmpty, !newURL.isEmpty else {
                                    alertMessage = "Title and URL must not be empty."
                                    showAlert = true
                                    return
                                }
                                
                                guard let url = URL(string: newURL), UIApplication.shared.canOpenURL(url) else {
                                    alertMessage = "Invalid URL format."
                                    showAlert = true
                                    return
                                }
                                
                                siteManager.addNewSite(title: newTitle, url: newURL, to: &sitesItems)
                                isSheetPresented = false
                            }) {
                                Image("SaveButton")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(.horizontal)
                            }
                            .frame(height: 56)
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .presentationDetents([.height(340)])
                    .presentationCornerRadius(40)
                    .background(Color.white)
                    .ignoresSafeArea(.all, edges: .bottom)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Error"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
            .fullScreenCover(item: $selectedItem) { item in
                SearchView(searchText: item.url)
            }
        }
    }
}

public class UserDefaultsService {
    private let key = "sitesItems"
    
    public func loadSitesItems() -> [SitesItem] {
        if let data = UserDefaults.standard.data(forKey: key) {
            let decoder = JSONDecoder()
            return (try? decoder.decode([SitesItem].self, from: data)) ?? []
        }
        return []
    }
    
    public func saveSitesItems(_ sitesItems: [SitesItem]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(sitesItems) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}

public struct SitesItem: Identifiable, Codable {
    public var id = UUID()
    var imageName: String
    var title: String
    var url: String
}

public final class SiteManager {
    private let userDefaultsService = UserDefaultsService()
    
    public func initializeDefaultSites(to sitesItems: inout [SitesItem]) {
        if userDefaultsService.loadSitesItems().isEmpty {
            let defaultSites = [
                SitesItem(imageName: "NetflixImage", title: "Netflix", url: "https://www.netflix.com/"),
                SitesItem(imageName: "FaceBookImage", title: "Facebook", url: "https://www.facebook.com/")
            ]
            sitesItems = defaultSites
            userDefaultsService.saveSitesItems(sitesItems)
        } else {
            sitesItems = UserDefaultsService().loadSitesItems()
        }
    }
    
    public func addNewSite(title: String, url: String, to sitesItems: inout [SitesItem]) {
        let newSite = SitesItem(imageName: "DefaultImage", title: title, url: url)
        sitesItems.append(newSite)
        userDefaultsService.saveSitesItems(sitesItems)
    }
    
    public func deleteSite(at index: Int, from sitesItems: inout [SitesItem]) {
        sitesItems.remove(at: index)
        userDefaultsService.saveSitesItems(sitesItems)
    }
}

public struct WebView: UIViewRepresentable {
    let searchText: String
    @Binding var shouldStartAutoscroll: Bool
    @Binding var shouldInjectClick: Bool
    @Binding var clickPosition: CGPoint?
    
    @State private var webView = WKWebView()
    
    public func makeUIView(context: Context) -> WKWebView {
        // Set up the web view
        webView.navigationDelegate = context.coordinator
        
        if let url = URL(string: "https://www.google.com/search?q=\(searchText)") {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // Start autoscrolling if the flag is set
        if shouldStartAutoscroll {
            context.coordinator.startAutoscroll(webView: webView)
        }
        
        // Inject click if the flag is set
        if shouldInjectClick, let position = clickPosition {
            injectClick(at: position)
        }
    }
    
    private func injectClick(at position: CGPoint) {
        let jsCode = """
        var event = new MouseEvent('click', {
            clientX: \(position.x),
            clientY: \(position.y),
            view: window,
            bubbles: true,
            cancelable: true
        });
        document.elementFromPoint(\(position.x), \(position.y)).dispatchEvent(event);
        """
        webView.evaluateJavaScript(jsCode, completionHandler: nil)
    }
    
    // Coordinator to handle WKWebView navigation delegate
    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        private var timer: Timer?

        init(parent: WebView) {
            self.parent = parent
        }
        
        // Called when page finishes loading
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Trigger the click once the page finishes loading
            if parent.shouldInjectClick, let clickPosition = parent.clickPosition {
                parent.injectClick(at: clickPosition)
            }
        }
        
        // Start autoscroll when required
        func startAutoscroll(webView: WKWebView) {
            // Avoid starting multiple timers
            guard timer == nil else { return }
            
            let distance = Settings.scrollDistance
            let speed = Settings.scrollSpeed
            let jsCode = "window.scrollBy(0, \(distance));"
            
            // Schedule timer on the main thread
            timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(speed), repeats: true) { _ in
                DispatchQueue.main.async {
                    webView.evaluateJavaScript(jsCode, completionHandler: nil)
                }
            }
        }

        // Invalidate the timer when it's no longer needed
        func invalidateTimer() {
            timer?.invalidate()
            timer = nil
        }
    }
    
    // Create and return the coordinator
    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}

public struct Settings {
    static var clickEverySeconds: Int {
        get { UserDefaults.standard.integer(forKey: "clickEverySeconds") == 0 ? 1 : UserDefaults.standard.integer(forKey: "clickEverySeconds") }
        set { UserDefaults.standard.set(newValue, forKey: "clickEverySeconds") }
    }
    
    static var numberOfClick: Int {
        get { UserDefaults.standard.integer(forKey: "numberOfClick") == 0 ? 1 : UserDefaults.standard.integer(forKey: "numberOfClick") }
        set { UserDefaults.standard.set(newValue, forKey: "numberOfClick") }
    }
    
    static var playSound: Bool {
        get { UserDefaults.standard.bool(forKey: "playSound") }
        set { UserDefaults.standard.set(newValue, forKey: "playSound") }
    }
    
    static var autoScroll: Bool {
        get { UserDefaults.standard.object(forKey: "autoScroll") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "autoScroll") }
    }
    
    static var scrollDistance: Double {
        get { UserDefaults.standard.double(forKey: "scrollDistance") == 0 ? 400 : UserDefaults.standard.double(forKey: "scrollDistance") }
        set { UserDefaults.standard.set(newValue, forKey: "scrollDistance") }
    }
    
    static var scrollSpeed: Double {
        get { UserDefaults.standard.double(forKey: "scrollSpeed") == 0 ? 10 : UserDefaults.standard.double(forKey: "scrollSpeed") }
        set { UserDefaults.standard.set(newValue, forKey: "scrollSpeed") }
    }
}

public struct SettingsMenuView: View {
    @Binding var clickEverySeconds: Int
    @Binding var numberOfClick: Int
    @Binding var playSound: Bool
    @Binding var autoScroll: Bool
    @Binding var scrollDistance: Double
    @Binding var scrollSpeed: Double
    @Binding var isMenuPressed: Bool
    @Binding var isClickerPressed: Bool
    @State private var showPayWall = false

    @State private var showsProPlanButton = true

    public var body: some View {
        if #available(iOS 16.4, *) {
            VStack(spacing: 20) {
                Spacer()
                
                Menu {
                    ForEach(1...60, id: \.self) { number in
                        Button("\(number) sec") {
                            clickEverySeconds = number
                        }
                    }
                } label: {
                    HStack {
                        Text("Click every")
                            .font(.system(size: 17))
                        
                        Spacer()
                        Text("\(clickEverySeconds) sec")
                            .foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                HStack {
                    Text("Number of click")
                        .foregroundColor(.white)
                    Spacer()
                    
                    CustomStepper(value: $numberOfClick)
                }
                .padding(.horizontal)
                
                Toggle(isOn: $playSound) {
                    Text("Play Sound")
                        .foregroundColor(.white)
                }
                .toggleStyle(.customDefault)
                .padding(.horizontal)
                
                Toggle(isOn: $autoScroll) {
                    HStack {
                        Text("Auto Scroll")
                            .foregroundColor(.white)
                    }
                }
                .toggleStyle(.customDefault)
                .padding(.horizontal)
                
                VStack {
                    HStack {
                        Text("Scroll Distance")
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(scrollDistance)) pixel")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Slider(value: $scrollDistance, in: 0...800, step: 50)
                        .accentColor(.white)
                }
                .padding(.horizontal)
                
                VStack {
                    HStack {
                        Text("Scroll Speed")
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(scrollSpeed)) sec")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Slider(value: $scrollSpeed, in: 1...60, step: 1)
                        .accentColor(.white)
                }
                .padding(.horizontal)
                
                Button(action: saveSettings) {
                    Image("SheetSaveButton")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal)
                }
                .frame(height: 56)
                
                Spacer()
                
                BottomButtonBar(isMenuPressed: $isMenuPressed, isClickerPressed: $isClickerPressed)
            }
            .presentationDetents([.height(565)])
            .presentationCornerRadius(40)
            .background(Color("CustomBlue"))
            .ignoresSafeArea(.all, edges: .bottom)
            .fullScreenCover(isPresented: $showPayWall) {
                PayWallView(fromOnboard: false)
            }
            .task {
                let purchased = await Wasdf.shared.wasdf()
                showsProPlanButton = purchased == nil
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func saveSettings() {
        Settings.clickEverySeconds = clickEverySeconds
        Settings.numberOfClick = numberOfClick
        Settings.playSound = playSound
        Settings.autoScroll = autoScroll
        Settings.scrollDistance = scrollDistance
        Settings.scrollSpeed = scrollSpeed
        isMenuPressed = false
    }
}

public struct CustomToggleStyle: ToggleStyle {

    var enabledColor: Color
    var disabledColor: Color
    var thumbColor: Color

    public func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            RoundedRectangle(cornerRadius: 15, style: .circular)
                .fill(configuration.isOn ? enabledColor : disabledColor)
                .frame(width: 56, height: 30)
                .overlay(
                    Circle()
                        .fill(thumbColor)
                        .padding(2)
                        .offset(x: configuration.isOn ? 13 : -13)
                )
                .onTapGesture {
                    withAnimation(.smooth(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

public extension ToggleStyle where Self == CustomToggleStyle {
    static func custom(enabledColor: Color, disabledColor: Color, thumbColor: Color) -> Self {
        Self(enabledColor: enabledColor, disabledColor: disabledColor, thumbColor: thumbColor)
    }

    static var customDefault: Self {
        custom(enabledColor: Color(red: 4/255, green: 4/255, blue: 4/255),
               disabledColor: Color(red: 219/255, green: 227/255, blue: 242/255),
               thumbColor: .white)
    }
}

public struct CustomStepper: View {
    @Binding var value: Int

    var minValue = 1
    var maxValue = 100
    var step = 1

    public var body: some View {
        HStack(spacing: 10) {
            Button {
                if value > minValue {
                    value -= 1
                }
            } label: {
                Text("-")
                    .font(.system(size: 24))
            }

            Text("\(value)")

            Button {
                if value < maxValue {
                    value += 1
                }
            } label: {
                Text("+")
                    .font(.system(size: 24))
            }
        }
        .foregroundStyle(.white.opacity(0.6))
        .font(.system(size: 16))
    }
}

public struct BottomButtonBar: View {
    @Binding var isMenuPressed: Bool
    @Binding var isClickerPressed: Bool
    @State var purchased: String?
    @State private var showPayWall = false

    public var body: some View {
        HStack {
            Button(action: {
                isMenuPressed.toggle()
            }) {
                Image(isMenuPressed ? "MenuButtonTrue" : "MenuButtonFalse")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            Spacer()
            Button(action: {
                if purchased == nil {
                    showPayWall.toggle()
                } else {
                    isClickerPressed.toggle()
                }
            }) {
                Image(isClickerPressed ? "StartClikerTrue" : "startClickerFalse")
                    .resizable()
                    .frame(width: 180, height: 50)
            }
        }
        .fullScreenCover(isPresented: $showPayWall) {
            PayWallView(fromOnboard: false)
        }
        .onAppear {
            Task {
                self.purchased = await Wasdf.shared.wasdf()
            }
        }
        .padding(20)
        .offset(y: -20)
    }
}

public struct SearchView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isMenuPressed = false
    @State private var isClickerPressed = false
    @State private var shouldStartAutoscroll = false
    @State private var shouldInjectClick = false
    @State private var clickPosition: CGPoint? = nil

    @State private var clickEverySeconds = Settings.clickEverySeconds
    @State private var numberOfClick = Settings.numberOfClick
    @State private var playSound = Settings.playSound
    @State private var autoScroll = Settings.autoScroll
    @State private var scrollDistance = Settings.scrollDistance
    @State private var scrollSpeed = Settings.scrollSpeed
    
    @State private var showPayWall = false
    
    let searchText: String

    @State private var buttonPositions: [(CGFloat, CGFloat)] = []
    
    public var body: some View {
        ZStack {
            Image("MainTabBarBackground")
                .resizable()
                .ignoresSafeArea()
            
            VStack {
                ZStack {
                    Text("Auto Clicker")
                        .font(.headline)
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(Color.gray)
                                Text("Back")
                                    .foregroundColor(Color.gray)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        }
                        Spacer()
                    }
                }
                
                WebView(searchText: searchText,
                        shouldStartAutoscroll: $shouldStartAutoscroll,
                        shouldInjectClick: $shouldInjectClick,
                        clickPosition: $clickPosition)
                    .cornerRadius(40)

                HStack {
                    Button(action: {
                        isMenuPressed.toggle()
                    }) {
                        Image(isMenuPressed ? "MenuButtonTrue" : "MenuButtonFalse")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }
                    Spacer()
                    Button(action: {
                        isClickerPressed.toggle()
                        
                        if isClickerPressed {
                            if Settings.autoScroll {
                                shouldStartAutoscroll = true
                            }
                            buttonPositions = (0..<3).map { _ in
                                (CGFloat.random(in: 0...UIScreen.main.bounds.width - 40),
                                 CGFloat.random(in: 0...UIScreen.main.bounds.height * 0.7 - 40))
                            }
                            
                            clickPosition = CGPoint(x: buttonPositions[0].0, y: buttonPositions[0].1)
                            shouldInjectClick = true
                        } else {
                            shouldStartAutoscroll = false
                        }
                    }) {
                        Image(isClickerPressed ? "StartClikerTrue" : "StartClickerFalse")
                            .resizable()
                            .frame(width: 180, height: 50)
                    }
                }
                .padding(.horizontal, 20)
            }

            if isClickerPressed {
                ForEach(0..<buttonPositions.count, id: \.self) { index in
                    Image(index == 0 ? "click1" : index == 1 ? "click2" : "click3")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .position(x: buttonPositions[index].0, y: buttonPositions[index].1)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    buttonPositions[index] = (value.location.x, value.location.y)
                                }
                        )
                        .onTapGesture {
                            if index == 0 {
                                print("click1 pressed")
                            } else if index == 1 {
                                print("click2 pressed")
                            } else if index == 2 {
                                print("click-3 pressed")
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $isMenuPressed) {
            SettingsMenuView(
                clickEverySeconds: $clickEverySeconds,
                numberOfClick: $numberOfClick,
                playSound: $playSound,
                autoScroll: $autoScroll,
                scrollDistance: $scrollDistance,
                scrollSpeed: $scrollSpeed,
                isMenuPressed: $isMenuPressed,
                isClickerPressed: $isClickerPressed
            )
        }
        .fullScreenCover(isPresented: $showPayWall) {
            PayWallView(fromOnboard: false)
        }
    }
}
