import SwiftUI
import AVFoundation   // 음성 안내(TTS), 알림음 등 (필요 시)
import Speech        // 음성 인식 (실제 구현 시 Info.plist 권한 추가 필요)

// MARK: - 전역 환경설정(접근성) 모델
class AccessibilitySettings: ObservableObject {
    @Published var isAccessibilityMode: Bool = false   // 휠체어/어린이 모드
    @Published var isLargeText: Bool = false           // 큰 글자 모드
    @Published var isHighContrast: Bool = false        // 고대비 모드
}

// MARK: - 메인(시작) 화면
struct KioskHomeView: View {
    @StateObject private var accessibilitySettings = AccessibilitySettings()
    @State private var storeNotice: String = "신메뉴 '딸기 라떼' 할인 중!"

    // 색상 테마
    let primaryColor = Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1))
    let secondaryColor = Color(#colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1))
    let backgroundColor = Color(#colorLiteral(red: 0.9568627477, green: 0.9568627477, blue: 0.9568627477, alpha: 1))

    func dynamicFont(_ baseSize: CGFloat) -> Font {
        let size = accessibilitySettings.isLargeText ? baseSize + 4 : baseSize
        return .system(size: size, weight: .semibold, design: .rounded)
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 25) {
                        noticeView
                        welcomeView
                        orderButtons
                        accessibilityButton
                        helpButton
                    }
                    .padding(.top, accessibilitySettings.isAccessibilityMode ? 100 : 20)
                    .padding(.horizontal)
                }
            }
            .navigationBarTitle("키오스크 홈", displayMode: .inline)
        }
        .environmentObject(accessibilitySettings)
    }

    var noticeView: some View {
        VStack(spacing: 4) {
            Text("매장 공지")
                .font(dynamicFont(18))
            Text(storeNotice)
                .font(dynamicFont(20))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.yellow.opacity(0.2))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        .accessibilityElement()
        .accessibilityLabel("매장 공지: \(storeNotice)")
    }

    var welcomeView: some View {
        VStack(spacing: 15) {
            Text("어서오세요!")
                .font(dynamicFont(32))
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            Image(systemName: "house.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(primaryColor)
                .accessibilityLabel("브랜드 로고")
        }
    }

    var orderButtons: some View {
        VStack(spacing: 20) {
            navigationButton(title: "주문하기", icon: "cart.fill", color: primaryColor, destination: OneStopOrderView())
            navigationButton(title: "음성으로 주문하기", icon: "waveform", color: secondaryColor, destination: VoiceOrderView())
            actionButton(title: "직원 호출", icon: "bell.fill", color: .red) {
                // 직원 호출 로직
            }
        }
    }

    var accessibilityButton: some View {
        navigationButton(title: "접근성 설정", icon: "person.crop.circle", color: .gray, destination: AccessibilityConfigView())
    }

    var helpButton: some View {
        navigationButton(title: "도움말 보기", icon: "questionmark.circle", color: .gray, destination: HelpView())
    }

    func navigationButton<Destination: View>(title: String, icon: String, color: Color, destination: Destination) -> some View {
        NavigationLink(destination: destination.environmentObject(accessibilitySettings)) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(dynamicFont(20))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
            )
            .foregroundColor(.white)
        }
        .accessibilityLabel("\(title) 버튼")
    }

    func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(dynamicFont(20))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
            )
            .foregroundColor(.white)
        }
        .accessibilityLabel("\(title) 버튼")
    }
}

// MARK: - 한 화면에서 카테고리별 메뉴와 장바구니를 확인하고 결제 화면으로 이동
struct OneStopOrderView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings

    // 카테고리
    let categories: [String] = ["세트메뉴", "단품", "음료", "디저트"]
    @State private var selectedCategory: String = "세트메뉴"

    // 장바구니
    @State private var cartItems: [String] = []

    // 간단 샘플 메뉴(하드코딩)
    func sampleMenus(for category: String) -> [MenuItem] {
        switch category {
        case "세트메뉴":
            return [
                MenuItem(name: "버거 세트", price: 7000, description: "버거+감자튀김+음료", imageName: "fork.knife.circle"),
                MenuItem(name: "치킨 세트", price: 8000, description: "치킨+감자튀김+음료", imageName: "fork.knife.circle")
            ]
        case "단품":
            return [
                MenuItem(name: "햄버거", price: 4000, description: "순쇠고기 패티 버거", imageName: "fork.knife.circle"),
                MenuItem(name: "치킨조각", price: 3000, description: "바삭 치킨 조각", imageName: "fork.knife.circle")
            ]
        case "음료":
            return [
                MenuItem(name: "콜라", price: 2000, description: "탄산이 톡 쏘는 콜라", imageName: "fork.knife.circle"),
                MenuItem(name: "사이다", price: 2000, description: "깔끔한 청량감 사이다", imageName: "fork.knife.circle"),
                MenuItem(name: "커피", price: 3000, description: "아메리카노 (HOT/ICE)", imageName: "fork.knife.circle"),
                MenuItem(name: "딸기 라떼", price: 3500, description: "신메뉴! 상큼한 딸기+우유", imageName: "fork.knife.circle")
            ]
        case "디저트":
            return [
                MenuItem(name: "아이스크림", price: 2500, description: "부드러운 바닐라 아이스크림", imageName: "fork.knife.circle"),
                MenuItem(name: "파이", price: 2000, description: "사과/고구마 파이 중 택1", imageName: "fork.knife.circle")
            ]
        default:
            return []
        }
    }

    // 폰트 동적 조절
    func dynamicFont(_ baseSize: CGFloat) -> Font {
        let size = accessibilitySettings.isLargeText ? baseSize + 4 : baseSize
        return .system(size: size)
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("간편 주문")
                .font(dynamicFont(28)).bold()
                .padding(.top)

            // 카테고리 선택
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categories, id: \.self) { category in
                        ScalableButton {
                            withAnimation {
                                selectedCategory = category
                            }
                        } label: {
                            Text(category)
                                .font(dynamicFont(18)).bold()
                                .padding()
                                .background(
                                    selectedCategory == category
                                    ? (accessibilitySettings.isHighContrast ? Color.black : Color.orange)
                                    : Color.gray
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .accessibilityLabel("\(category) 카테고리 버튼")
                    }
                }
                .padding(.horizontal)
            }

            // 선택된 카테고리의 메뉴 리스트
            let menus = sampleMenus(for: selectedCategory)
            if menus.isEmpty {
                Text("아직 준비된 메뉴가 없습니다.")
                    .font(dynamicFont(18))
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(menus, id: \.id) { menu in
                            ScalableButton {
                                // 메뉴를 장바구니에 담기
                                cartItems.append(menu.name)
                            } label: {
                                HStack {
                                    Image(systemName: menu.imageName)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.blue)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(menu.name)
                                            .font(dynamicFont(20)).bold()
                                        Text("₩\(menu.price)")
                                            .font(dynamicFont(16))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 1)
                            }
                            .accessibilityLabel("\(menu.name) 장바구니에 담기 버튼")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }

            // 장바구니 영역
            VStack(spacing: 8) {
                Text("장바구니 (\(cartItems.count)개)")
                    .font(dynamicFont(20)).bold()

                if cartItems.isEmpty {
                    Text("아직 메뉴를 담지 않았습니다.")
                        .font(dynamicFont(16))
                        .foregroundColor(.secondary)
                } else {
                    // 간단 리스트
                    ScrollView {
                        ForEach(cartItems.indices, id: \.self) { idx in
                            HStack {
                                Text(cartItems[idx])
                                    .font(dynamicFont(16))
                                Spacer()
                                // 삭제 버튼
                                Button(action: {
                                    cartItems.remove(at: idx)
                                }, label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                })
                                .accessibilityLabel("장바구니 \(cartItems[idx]) 삭제 버튼")
                            }
                            .padding(.horizontal)
                        }
                    }
                    .frame(height: 100) // 적절히 높이 제한
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)

            // "결제하기" 버튼 → 별도 PaymentView로 이동
            NavigationLink(
                destination: PaymentView(
                    totalPrice: cartItems.count * 5000 // 간단히 개수 × 5000원으로 가정
                ).environmentObject(accessibilitySettings)
            ) {
                Text("결제하기")
                    .font(dynamicFont(20)).bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(accessibilitySettings.isHighContrast ? Color.black : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .accessibilityLabel("결제 화면으로 이동")

            Spacer()
        }
        .navigationBarTitle("간편 주문", displayMode: .inline)
    }
}

// MARK: - 결제 전용 화면
struct PaymentView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    let totalPrice: Int

    @State private var paymentStatus: String? = nil

    // 폰트 동적 조절
    func dynamicFont(_ baseSize: CGFloat) -> Font {
        let size = accessibilitySettings.isLargeText ? baseSize + 4 : baseSize
        return .system(size: size)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("결제 화면")
                .font(dynamicFont(28)).bold()
                .padding(.top)

            Text("총 결제 금액: ₩\(totalPrice)")
                .font(dynamicFont(22)).bold()

            // 안내문구: 카드를 꽂아주세요
            Text("카드를 꽂아주세요")
                .font(dynamicFont(20))
                .padding(.bottom, 10)

            // 실제 결제 시뮬레이션 (카드/현금)
            HStack(spacing: 16) {
                // 카드 결제 시뮬레이션 버튼
                ScalableButton {
                    simulatePayment(success: true)
                } label: {
                    VStack {
                        Image(systemName: "creditcard.fill")
                            .resizable()
                            .frame(width: 40, height: 28)
                        Text("카드 결제")
                            .font(dynamicFont(16)).bold()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(accessibilitySettings.isHighContrast ? Color.black : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // 현금 결제 시뮬레이션 버튼
                ScalableButton {
                    simulatePayment(success: false)
                } label: {
                    VStack {
                        Image(systemName: "banknote.fill")
                            .resizable()
                            .frame(width: 40, height: 28)
                        Text("현금 결제")
                            .font(dynamicFont(16)).bold()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(accessibilitySettings.isHighContrast ? Color.black : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            // 결제 결과 메시지
            if let paymentStatus = paymentStatus {
                Text(paymentStatus)
                    .font(dynamicFont(18)).bold()
                    .foregroundColor(paymentStatus.contains("성공") ? .green : .red)
                    .padding(.top, 8)
                    .accessibilityLabel("결제 결과: \(paymentStatus)")
            }

            Spacer()
        }
        .padding(.bottom, 20)
        .navigationBarTitle("결제 진행", displayMode: .inline)
    }

    // 결제 시뮬레이션 로직
    func simulatePayment(success: Bool) {
        if success {
            paymentStatus = "결제 성공! 주문이 완료되었습니다."
        } else {
            paymentStatus = "결제 실패! 다시 시도해주세요."
        }
    }
}

// MARK: - 음성 인식 주문 화면(간단 예시)
struct VoiceOrderView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings

    @State private var isListening: Bool = false
    @State private var recognizedText: String = "음성 인식 대기 중..."
    @State private var cartItems: [String] = []

    func dynamicFont(_ baseSize: CGFloat) -> Font {
        let size = accessibilitySettings.isLargeText ? baseSize + 4 : baseSize
        return .system(size: size)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("음성 주문 화면")
                .font(dynamicFont(28)).bold()
                .padding(.top)

            Text(recognizedText)
                .font(dynamicFont(18))
                .padding()

            // 음성 듣기 시작/중지
            HStack {
                ScalableButton {
                    startListening()
                } label: {
                    Text("음성 듣기 시작")
                        .font(dynamicFont(18)).bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(accessibilitySettings.isHighContrast ? Color.black : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                ScalableButton {
                    stopListening()
                } label: {
                    Text("음성 듣기 중지")
                        .font(dynamicFont(18)).bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(accessibilitySettings.isHighContrast ? Color.black : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            // 장바구니 미니 리스트
            Text("인식으로 추가된 장바구니:")
                .font(dynamicFont(18)).bold()
            ForEach(cartItems, id: \.self) { item in
                Text("· \(item)")
                    .font(dynamicFont(18))
            }

            Spacer()
        }
        .padding()
        .navigationBarTitle("음성 주문", displayMode: .inline)
    }

    func startListening() {
        isListening = true
        recognizedText = "음성을 듣고 있습니다..."
        // 실제 음성 인식 로직(마이크 권한, SFSpeechRecognizer 등) 필요
    }

    func stopListening() {
        isListening = false
        recognizedText = "음성 인식을 중지했습니다."
        // 실제 STT 결과 반영해서 cartItems에 추가하는 로직 필요
    }
}

// MARK: - 접근성 설정 화면
struct AccessibilityConfigView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings

    var body: some View {
        Form {
            Section(header: Text("접근성 옵션")) {
                Toggle("화면 아래로 정렬(휠체어/어린이 모드)", isOn: $accessibilitySettings.isAccessibilityMode)
                Toggle("글씨 크게 보기", isOn: $accessibilitySettings.isLargeText)
                Toggle("고대비 모드", isOn: $accessibilitySettings.isHighContrast)
            }
        }
        .navigationBarTitle("접근성 설정", displayMode: .inline)
    }
}

// MARK: - 도움말(Help) 화면
struct HelpView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings

    func dynamicFont(_ baseSize: CGFloat) -> Font {
        let size = accessibilitySettings.isLargeText ? baseSize + 4 : baseSize
        return .system(size: size)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("도움말 화면")
                    .font(dynamicFont(28)).bold()
                    .accessibilityAddTraits(.isHeader)

                Text("""
- [주문하기] 버튼을 눌러 카테고리를 선택한 뒤, 원하는 메뉴를 선택하면 장바구니에 추가됩니다.
- 장바구니에서 [결제하기] 버튼을 누르시면 결제 화면으로 이동합니다.
- 결제 화면에서 "카드를 꽂아주세요" 안내에 따라 카드 결제를 진행하시거나, 현금을 선택하실 수 있습니다.
- [음성으로 주문하기] 화면에서는 음성 명령을 통해 메뉴를 담을 수 있습니다(실제 앱에서는 마이크 권한 필요).
- [접근성 설정]에서 어린이/장애인/노인 모드를 위한 여러 옵션(글자 크게, 고대비 등)을 사용하세요.
- 화면에 표시되는 안내 문구를 잘 확인하시고, 필요 시 [직원 호출] 버튼을 눌러 도움을 받으세요.
""")
                    .font(dynamicFont(18))

                Spacer()
            }
            .padding()
        }
        .navigationBarTitle("도움말", displayMode: .inline)
    }
}

// MARK: - 메뉴 상세 정보 모델 (예시용)
struct MenuItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Int
    let description: String
    let imageName: String
}

// MARK: - ScalableButton: 버튼 탭 시 살짝 커지는 애니메이션 효과
struct ScalableButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label

    @State private var isPressed: Bool = false

    init(action: @escaping () -> Void,
         @ViewBuilder label: @escaping () -> Label)
    {
        self.action = action
        self.label = label
    }

    var body: some View {
        Button {
            action()
        } label: {
            label()
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeIn(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - 미리보기
struct KioskHomeView_Previews: PreviewProvider {
    static var previews: some View {
        KioskHomeView()
    }
}
