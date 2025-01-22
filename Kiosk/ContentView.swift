import SwiftUI
import AVFoundation
import Speech

// MARK: - 데이터 모델
struct MenuItem: Identifiable, Hashable {
    let id = UUID()
    let category: String
    let name: String
    let price: Int
    let description: String
    let icon: String
}

struct CartItem: Identifiable {
    let id = UUID()
    let item: MenuItem
    var quantity: Int
}

// MARK: - 전역 설정
class AccessibilitySettings: ObservableObject {
    @Published var isAccessibilityMode = false
    @Published var isLargeText = false
    @Published var isHighContrast = false
}

// MARK: - 디자인 시스템
struct AppColor {
    static let primary = Color(#colorLiteral(red: 0.44, green: 0.31, blue: 0.22, alpha: 1))
    static let secondary = Color(#colorLiteral(red: 0.85, green: 0.65, blue: 0.45, alpha: 1))
    static let accent = Color(#colorLiteral(red: 0.92, green: 0.49, blue: 0.32, alpha: 1))
    static let background = Color(#colorLiteral(red: 0.96, green: 0.94, blue: 0.91, alpha: 1))
    static let card = Color.white
    static let textPrimary = Color(#colorLiteral(red: 0.15, green: 0.11, blue: 0.07, alpha: 1))
    static let textSecondary = Color(#colorLiteral(red: 0.44, green: 0.44, blue: 0.44, alpha: 1))
}

struct AppFont {
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium, design: .rounded) }
}

// MARK: - 메인 홈 화면
struct KioskHomeView: View {
    @StateObject var settings = AccessibilitySettings()
    @State private var cartItems: [CartItem] = []

    var body: some View {
        NavigationView {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        NotificationBanner()
                        BrandHeader()
                        MainActionGrid(cartItems: $cartItems)
                        QuickMenuSection()
                        SettingsSection()
                    }
                    .padding(.vertical, 30)
                }
            }
            .navigationTitle("☕️ Bean & Brew")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Bean & Brew")
                        .font(AppFont.bold(22))
                        .foregroundColor(AppColor.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    CartButton(cartItems: $cartItems)
                }
            }
        }
        .environmentObject(settings)
    }
}

// MARK: - 홈 화면 컴포넌트
struct NotificationBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "leaf.fill")
            Text("🎃 가을 시즌 한정 메뉴! 호박 스파이스 라떼 10% 할인")
                .font(AppFont.medium(16))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(LinearGradient(gradient: Gradient(colors: [AppColor.accent, Color.orange]), startPoint: .leading, endPoint: .trailing))
        .foregroundColor(.white)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

struct BrandHeader: View {
    @EnvironmentObject var settings: AccessibilitySettings

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColor.primary)

            Text("원두의 향기, 특별한 순간")
                .font(settings.isLargeText ? AppFont.medium(18) : AppFont.medium(16))
                .foregroundColor(AppColor.textSecondary)
        }
    }
}

struct MainActionGrid: View {
    @Binding var cartItems: [CartItem]

    var body: some View {
        VStack(spacing: 15) {
            NavigationLink(destination: MenuOrderView(cartItems: $cartItems)) {
                ActionButton(icon: "mug.fill", title: "메뉴 주문", subtitle: "직접 선택하여 주문")
            }

            NavigationLink(destination: VoiceOrderView()) {
                ActionButton(icon: "waveform", title: "음성 주문", subtitle: "말로 쉽게 주문")
            }

            Button(action: {}) {
                ActionButton(icon: "gift.fill", title: "e-Gift Card", subtitle: "디지털 상품권 구매")
            }
        }
        .padding(.horizontal, 20)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title)
                .frame(width: 50)

            VStack(alignment: .leading) {
                Text(title).font(AppFont.bold(18))
                Text(subtitle).font(AppFont.medium(14))
            }
            Spacer()
        }
        .padding(20)
        .foregroundColor(.white)
        .background(AppColor.primary)
        .cornerRadius(15)
    }
}

struct QuickMenuSection: View {
    let quickMenus = [
        ("☕️ 아메리카노", "2,500원"),
        ("🍵 녹차 라떼", "3,800원"),
        ("🥐 크루아상", "3,200원"),
        ("🎁 e-Gift Card", "선물하기")
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            ForEach(quickMenus, id: \.0) { item in
                QuickMenuItem(title: item.0, price: item.1)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct QuickMenuItem: View {
    let title: String
    let price: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title).font(AppFont.medium(16))
                Text(price).font(AppFont.medium(14))
            }
            Spacer()
        }
        .padding(15)
        .background(AppColor.card)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - 메뉴 주문 화면
struct MenuOrderView: View {
    @EnvironmentObject var settings: AccessibilitySettings
    @Binding var cartItems: [CartItem]
    @State private var selectedCategory = 0

    let categories = ["에스프레소", "브루드", "차", "베이커리", "시즌"]
    let menuItems: [[MenuItem]] = [
        [
            MenuItem(category: "에스프레소", name: "아메리카노", price: 2500, description: "에스프레소 샷 + 뜨거운 물", icon: "☕️"),
            MenuItem(category: "에스프레소", name: "카페 라떼", price: 3500, description: "우유와 에스프레소의 조화", icon: "🥛")
        ],
        [
            MenuItem(category: "브루드", name: "콜드 브루", price: 3800, description: "12시간 추출 커피", icon: "💧"),
            MenuItem(category: "브루드", name: "디카페인", price: 4000, description: "카페인 FREE", icon: "🌱")
        ],
        [
            MenuItem(category: "차", name: "녹차 라떼", price: 3800, description: "신선한 말차 파우더", icon: "🍵"),
            MenuItem(category: "차", name: "히비스커스 티", price: 3200, description: "상큼한 허브 티", icon: "🌺")
        ],
        [
            MenuItem(category: "베이커리", name: "크루아상", price: 3200, description: "버터 풍미 가득", icon: "🥐"),
            MenuItem(category: "베이커리", name: "마들렌", price: 2800, description: "수제 마들렌 3개", icon: "🧁")
        ],
        [
            MenuItem(category: "시즌", name: "호박 라떼", price: 4200, description: "가을 한정 메뉴", icon: "🎃"),
            MenuItem(category: "시즌", name: "아이스 초코", price: 3800, description: "진한 초콜릿 풍미", icon: "❄️")
        ]
    ]

    var body: some View {
        VStack(spacing: 0) {
            CategoryTabBar(selectedCategory: $selectedCategory)

            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(menuItems[selectedCategory], id: \.id) { item in
                        MenuItemView(item: item, cartItems: $cartItems)
                    }
                }
                .padding(20)
            }

            OrderSummaryView(cartItems: $cartItems)
        }
        .background(AppColor.background)
    }
}

struct CategoryTabBar: View {
    @Binding var selectedCategory: Int
    let categories = ["에스프레소", "브루드", "차", "베이커리", "시즌"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(0..<categories.count, id: \.self) { index in
                    Button(action: { selectedCategory = index }) {
                        Text(categories[index])
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(selectedCategory == index ? AppColor.primary : Color.clear)
                            .cornerRadius(20)
                            .foregroundColor(selectedCategory == index ? .white : AppColor.textPrimary)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .background(AppColor.card.shadow(radius: 2))
    }
}

struct MenuItemView: View {
    let item: MenuItem
    @Binding var cartItems: [CartItem]

    private var quantity: Int {
        cartItems.first(where: { $0.item.id == item.id })?.quantity ?? 0
    }

    var body: some View {
        HStack(spacing: 15) {
            Text(item.icon).font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(AppFont.bold(16))
                Text(item.description).font(AppFont.medium(14)).foregroundColor(AppColor.textSecondary)
            }

            Spacer()

            VStack {
                Text("\(item.price)원").font(AppFont.medium(16))
                HStack {
                    Button(action: decreaseQuantity) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(quantity > 0 ? AppColor.accent : .gray)
                    }
                    .disabled(quantity == 0)

                    Text("\(quantity)")
                        .font(AppFont.medium(16))
                        .frame(width: 30)

                    Button(action: increaseQuantity) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColor.accent)
                    }
                }
            }
        }
        .padding(15)
        .background(AppColor.card)
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func increaseQuantity() {
        if let index = cartItems.firstIndex(where: { $0.item.id == item.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(item: item, quantity: 1))
        }
    }

    private func decreaseQuantity() {
        guard let index = cartItems.firstIndex(where: { $0.item.id == item.id }) else { return }
        if cartItems[index].quantity > 1 {
            cartItems[index].quantity -= 1
        } else {
            cartItems.remove(at: index)
        }
    }
}

// MARK: - 주문 요약
struct OrderSummaryView: View {
    @Binding var cartItems: [CartItem]

    var totalPrice: Int {
        cartItems.reduce(0) { $0 + ($1.item.price * $1.quantity) }
    }

    var body: some View {
        VStack(spacing: 15) {
            NavigationLink(destination: CartDetailView(cartItems: $cartItems)) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("주문 예정 \(cartItems.count)개")
                            .font(AppFont.bold(16))
                        Text("\(totalPrice)원")
                            .font(AppFont.medium(14))
                            .foregroundColor(AppColor.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(AppColor.card)
                .cornerRadius(12)
            }

            NavigationLink(destination: PaymentView(cartItems: $cartItems)) {
                Text("결제 진행하기")
                    .font(AppFont.bold(16))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColor.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(20)
        .background(AppColor.card.shadow(radius: 5))
    }
}

// MARK: - 장바구니 상세 화면
struct CartDetailView: View {
    @Binding var cartItems: [CartItem]
    @Environment(\.presentationMode) var presentationMode

    var totalPrice: Int {
        cartItems.reduce(0) { $0 + ($1.item.price * $1.quantity) }
    }

    var body: some View {
        VStack {
            List {
                ForEach(cartItems) { cartItem in
                    HStack {
                        Text(cartItem.item.icon)
                            .font(.system(size: 32))
                        VStack(alignment: .leading) {
                            Text(cartItem.item.name)
                                .font(AppFont.bold(16))
                            Text("\(cartItem.item.price)원 x \(cartItem.quantity)")
                                .font(AppFont.medium(14))
                                .foregroundColor(AppColor.textSecondary)
                        }
                        Spacer()
                        Text("\(cartItem.item.price * cartItem.quantity)원")
                            .font(AppFont.medium(16))
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            if let index = cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                                cartItems.remove(at: index)
                            }
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)

            VStack(spacing: 15) {
                HStack {
                    Text("총 결제 금액")
                        .font(AppFont.bold(18))
                    Spacer()
                    Text("\(totalPrice)원")
                        .font(AppFont.bold(18))
                }

                NavigationLink(destination: PaymentView(cartItems: $cartItems)) {
                    Text("결제 진행하기")
                        .font(AppFont.bold(16))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColor.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(AppColor.card.shadow(radius: 5))
        }
        .navigationTitle("장바구니")
    }
}

// MARK: - 결제 화면
struct PaymentView: View {
    @Binding var cartItems: [CartItem]
    @Environment(\.presentationMode) var presentationMode
    @State private var paymentSuccess = false
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 30) {
            if isProcessing {
                ProgressView()
                    .scaleEffect(2.0)
                Text("결제 처리 중...")
                    .font(AppFont.medium(18))
            } else {
                Image(systemName: paymentSuccess ? "checkmark.circle.fill" : "creditcard.fill")
                    .font(.system(size: 80))
                    .foregroundColor(paymentSuccess ? .green : AppColor.primary)

                Text(paymentSuccess ? "결제 완료!" : "결제 수단 선택")
                    .font(AppFont.bold(24))

                if !paymentSuccess {
                    HStack(spacing: 20) {
                        Button(action: { processPayment() }) {
                            PaymentMethodView(icon: "creditcard.fill", label: "카드 결제")
                        }

                        Button(action: { processPayment() }) {
                            PaymentMethodView(icon: "wonsign.circle.fill", label: "현금 결제")
                        }
                    }
                }

                Button(action: {
                    if paymentSuccess {
                        cartItems.removeAll()
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(paymentSuccess ? "완료" : "취소")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColor.secondary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(30)
        .background(AppColor.background)
    }

    func processPayment() {
        isProcessing = true
        // 2초 후 결제 성공 시뮬레이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            paymentSuccess = true
            isProcessing = false
        }
    }
}

struct PaymentMethodView: View {
    let icon: String
    let label: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 40))
            Text(label).font(AppFont.medium(16))
        }
        .padding(20)
        .frame(width: 150)
        .background(AppColor.card)
        .cornerRadius(12)
    }
}

// MARK: - 추가 컴포넌트
struct CartButton: View {
    @Binding var cartItems: [CartItem]

    var itemCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "cart.fill")
                .font(.title)

            if itemCount > 0 {
                Text("\(itemCount)")
                    .font(.caption)
                    .padding(5)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .offset(x: 10, y: -10)
            }
        }
        .foregroundColor(AppColor.textPrimary)
    }
}

// MARK: - 설정 관련 뷰
struct SettingsSection: View {
    var body: some View {
        HStack {
            NavigationLink(destination: AccessibilityConfigView()) {
                SettingItem(icon: "person.crop.circle", title: "접근성")
            }
            NavigationLink(destination: HelpView()) {
                SettingItem(icon: "questionmark.circle", title: "도움말")
            }
        }
        .padding(.horizontal, 20)
    }
}

struct SettingItem: View {
    let icon: String
    let title: String

    var body: some View {
        VStack {
            Image(systemName: icon).font(.title)
            Text(title).font(AppFont.medium(14))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColor.card)
        .cornerRadius(12)
    }
}

struct AccessibilityConfigView: View {
    @EnvironmentObject var settings: AccessibilitySettings

    var body: some View {
        Form {
            Section(header: Text("접근성 설정")) {
                Toggle("큰 글자 모드", isOn: $settings.isLargeText)
                Toggle("고대비 모드", isOn: $settings.isHighContrast)
            }
        }
        .navigationTitle("설정")
    }
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("자주 묻는 질문")
                    .font(AppFont.bold(24))
                    .padding(.bottom)

                HelpItem(question: "주문 방법", answer: "메뉴를 선택 후 수량을 조절하고 장바구니에 추가하세요.")
                HelpItem(question: "결제 방법", answer: "카드 또는 현금 결제를 선택할 수 있습니다.")
                HelpItem(question: "환불 정책", answer: "제조 시작 전까지 주문 취소가 가능합니다.")
            }
            .padding()
        }
        .navigationTitle("도움말")
    }
}

struct HelpItem: View {
    let question: String
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(AppFont.bold(18))
                .foregroundColor(AppColor.primary)
            Text(answer)
                .font(AppFont.medium(16))
        }
        .padding()
        .background(AppColor.card)
        .cornerRadius(12)
    }
}

// MARK: - 기타 뷰
struct VoiceOrderView: View {
    var body: some View {
        Text("음성 주문 화면")
            .navigationTitle("🎤 음성 주문")
    }
}

// MARK: - 프리뷰
struct KioskHomeView_Previews: PreviewProvider {
    static var previews: some View {
        KioskHomeView()
    }
}

struct MenuOrderView_Previews: PreviewProvider {
    static var previews: some View {
        MenuOrderView(cartItems: .constant([]))
    }
}

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(cartItems: .constant([]))
    }
}

