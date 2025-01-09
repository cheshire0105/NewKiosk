import SwiftUI
import AVFoundation   // 음성 안내(TTS), 알림음 등 (필요시)
import Speech        // 음성 인식 (실제 구현 시 Info.plist 권한 추가 필요)

// MARK: - 전역 환경설정(접근성) 모델
class AccessibilitySettings: ObservableObject {
    @Published var isAccessibilityMode: Bool = false   // 화면 하단 재배치
    @Published var isLargeText: Bool = false           // 큰 글자 모드
    @Published var isHighContrast: Bool = false        // 고대비 모드
}

// MARK: - 메인(시작) 화면
struct KioskHomeView: View {
    @StateObject private var accessibilitySettings = AccessibilitySettings()

    // 매장별 안내용 배너 텍스트
    @State private var storeNotice: String = "오늘은 신메뉴 '딸기 라떼'가 할인 중!"
    @State private var showScrollHint: Bool = true

    // 디자인 관련: 폰트 크기를 접근성 세팅에 따라 다르게
    func dynamicFont(_ baseSize: CGFloat) -> Font {
        // 큰 글자 모드이면 +4
        let size = accessibilitySettings.isLargeText ? baseSize + 4 : baseSize
        return .system(size: size)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                // 상단 배너(공지)
                if !storeNotice.isEmpty {
                    VStack {
                        Text("매장 공지")
                            .font(dynamicFont(18)).bold()
                            .padding(.bottom, 4)
                        Text(storeNotice)
                            .font(dynamicFont(20)).bold()
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.25))
                    .cornerRadius(12)
                    .accessibilityElement()
                    .accessibilityLabel("매장 공지: \(storeNotice)")
                }

                Spacer()

                Text("어서오세요!")
                    .font(dynamicFont(28)).bold()
                    .accessibilityAddTraits(.isHeader)

                // 브랜드 로고(예시)
                Image(systemName: "house.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .accessibilityLabel("브랜드 로고 - 예시 이미지")

                // 주문하기 버튼 (확실한 탭 효과)
                ScalableButton(action: {}) {
                    NavigationLink(destination: MenuSelectionView()
                        .environmentObject(accessibilitySettings)) {
                        Text("주문하기")
                            .font(dynamicFont(22)).bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(accessibilitySettings.isHighContrast ? Color.black : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 50)
                .accessibilityLabel("주문하기 버튼")

                // 음성 인식 기반 주문 (간단 예시)
                ScalableButton {
                    // 이동
                } label: {
                    NavigationLink(destination: VoiceOrderView().environmentObject(accessibilitySettings)) {
                        Text("음성으로 주문하기")
                            .font(dynamicFont(20)).bold()
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(accessibilitySettings.isHighContrast ? Color.black : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 50)
                .accessibilityLabel("음성으로 주문하기 버튼")

                // 직원 호출
                ScalableButton {
                    // 실제직원 호출 로직(서버, BLE, 알람) 등
                } label: {
                    Text("직원 호출")
                        .font(dynamicFont(20)).bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(accessibilitySettings.isHighContrast ? Color.black : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 50)
                .accessibilityLabel("직원 호출 버튼")

                // 접근성 설정 들어가기
                NavigationLink(destination: AccessibilityConfigView()
                    .environmentObject(accessibilitySettings)) {
                    Text("접근성 설정")
                        .font(dynamicFont(18)).bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(accessibilitySettings.isHighContrast ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 50)
                .accessibilityLabel("접근성 설정 화면으로 이동")

                Spacer()

                // 도움말 보기
                NavigationLink(destination: HelpView().environmentObject(accessibilitySettings)) {
                    Text("도움말 보기")
                        .font(dynamicFont(18)).bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(accessibilitySettings.isHighContrast ? Color.black : Color.gray.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .accessibilityLabel("도움말 보기 버튼")
                .padding(.horizontal, 50)

                Spacer()
            }
            // 접근성 모드에서 top padding 증가
            .padding(.top, accessibilitySettings.isAccessibilityMode ? 100 : 20)
            .navigationBarTitle("키오스크 홈", displayMode: .inline)
            .onAppear {
                // 4초 후 스크롤 힌트 숨김
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    showScrollHint = false
                }
            }
            .overlay(
                VStack {
                    if showScrollHint {
                        Text("아래로 스크롤하시면 더 많은 메뉴를 볼 수 있습니다 \u{2B07}")
                            .font(.footnote)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .transition(.opacity)
                            .padding()
                    }
                    Spacer()
                }
            )
        }
        // 전역 환경객체 적용(접근성 세팅)
        .environmentObject(accessibilitySettings)
    }
}

// MARK: - ScalableButton: 버튼 탭 시 살짝 커지는 애니메이션 효과
struct ScalableButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label

    @State private var isPressed: Bool = false

    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }

    var body: some View {
        Button {
            // 실제 클릭 시 동작
            action()
        } label: {
            label()
                .scaleEffect(isPressed ? 0.95 : 1.0) // 눌렸을 때 살짝 줄이는 애니메이션
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

// MARK: - 음성 인식 주문 화면(간단 예시)
struct VoiceOrderView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings

    @State private var isListening: Bool = false
    @State private var recognizedText: String = "음성 인식 대기 중..."

    // 예시 장바구니
    @State private var cartItems: [String] = []

    func startListening() {
        // 실제 구현 시 iOS 음성 인식 세팅 (SFSpeechRecognizer 등)
        isListening = true
        recognizedText = "음성을 듣고 있습니다..."
        // 예: STT 결과를 파싱하여 특정 키워드가 나오면 메뉴 추가
    }

    func stopListening() {
        isListening = false
        // 예: 인식 종료 → recognizedText 업데이트
        recognizedText = "음성 인식을 중지했습니다."
    }

    func processRecognitionResult(_ text: String) {
        // 예시 로직: "햄버거"가 포함되어 있으면 cartItems.append("햄버거")
        if text.contains("햄버거") {
            cartItems.append("햄버거")
        }
        // 추가 로직: "사이다", "커피" 등 키워드 처리
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("음성 주문 화면")
                .font(.system(size: accessibilitySettings.isLargeText ? 28 : 24))
                .bold()
                .padding(.top)

            Text(recognizedText)
                .font(.system(size: accessibilitySettings.isLargeText ? 22 : 18))
                .padding()

            // 음성 듣기 시작/중지
            HStack {
                ScalableButton {
                    startListening()
                } label: {
                    Text("음성 듣기 시작")
                        .font(.system(size: accessibilitySettings.isLargeText ? 22 : 18))
                        .bold()
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
                        .font(.system(size: accessibilitySettings.isLargeText ? 22 : 18))
                        .bold()
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
                .font(.system(size: accessibilitySettings.isLargeText ? 20 : 16))
                .bold()
            ForEach(cartItems, id: \.self) { item in
                Text("· \(item)")
                    .font(.system(size: accessibilitySettings.isLargeText ? 20 : 16))
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // 마이크 권한 요청, SFSpeechRecognizer 권한 요청 등 실제 구현 필요
        }
        .navigationBarTitle("음성 주문", displayMode: .inline)
    }
}

// MARK: - 메뉴 선택 화면
struct MenuSelectionView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings

    let categories: [String] = ["세트메뉴", "단품", "음료", "디저트"]
    @State private var selectedCategory: String = "세트메뉴"
    @State private var cartItems: [String] = []

    // “각 매장 고유 메뉴” 등을 위해 서버로부터 받아올 수도 있으나, 예시에선 하드코딩
    func sampleMenus(for category: String) -> [MenuItem] {
        switch category {
        case "세트메뉴":
            return [
                MenuItem(name: "버거 세트", price: 7000, description: "버거+감자튀김+음료 포함", imageName: "fork.knife.circle"),
                MenuItem(name: "치킨 세트", price: 8000, description: "치킨+감자튀김+음료 포함", imageName: "fork.knife.circle")
            ]
        case "단품":
            return [
                MenuItem(name: "햄버거", price: 4000, description: "순쇠고기 패티, 양상추, 토마토 포함", imageName: "fork.knife.circle"),
                MenuItem(name: "치킨조각", price: 3000, description: "바삭하게 튀긴 치킨 조각", imageName: "fork.knife.circle")
            ]
        case "음료":
            return [
                MenuItem(name: "콜라", price: 2000, description: "탄산이 톡 쏘는 콜라", imageName: "fork.knife.circle"),
                MenuItem(name: "사이다", price: 2000, description: "깔끔한 청량감의 사이다", imageName: "fork.knife.circle"),
                MenuItem(name: "커피", price: 3000, description: "아메리카노 (HOT/ICE)", imageName: "fork.knife.circle"),
                MenuItem(name: "딸기 라떼", price: 3500, description: "신메뉴! 상큼한 딸기+우유", imageName: "fork.knife.circle")
            ]
        case "디저트":
            return [
                MenuItem(name: "아이스크림", price: 2500, description: "부드러운 바닐라 아이스크림", imageName: "fork.knife.circle"),
                MenuItem(name: "파이", price: 2000, description: "사과 또는 고구마가 들어간 파이", imageName: "fork.knife.circle")
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

    @State private var selectedMenuDetail: MenuItem? = nil
    @State private var showDetailSheet: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("메뉴 선택 화면")
                .font(dynamicFont(28)).bold()
                .accessibilityAddTraits(.isHeader)
                .padding(.top)

            // 카테고리 스크롤 영역
            Text("아래 카테고리를 눌러 메뉴를 선택해보세요.")
                .font(dynamicFont(18))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categories, id: \.self) { category in
                        ScalableButton {
                            withAnimation {
                                selectedCategory = category
                            }
                        } label: {
                            Text("\(category)")
                                .font(dynamicFont(18)).bold()
                                .padding()
                                .frame(minWidth: 100)
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

            let menuItems = sampleMenus(for: selectedCategory)
            if menuItems.isEmpty {
                Text("아직 준비된 메뉴가 없습니다.")
                    .foregroundColor(.secondary)
            } else {
                Text("아래로 스크롤하여 메뉴를 더 확인하세요 \u{2B07}")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(menuItems, id: \.name) { item in
                            ScalableButton {
                                // 상세 정보 Sheet 열기
                                selectedMenuDetail = item
                                showDetailSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: item.imageName)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.blue)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(dynamicFont(20)).bold()
                                        Text("₩\(item.price)")
                                            .font(dynamicFont(16))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 1)
                            }
                            .accessibilityLabel("\(item.name) 상세 보기 버튼")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }

            // 장바구니로 이동 버튼
            NavigationLink(destination: CartView(cartItems: cartItems)
                .environmentObject(accessibilitySettings)) {
                Text("장바구니 확인 (\(cartItems.count)개)")
                    .font(dynamicFont(20)).bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(accessibilitySettings.isHighContrast ? Color.black : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .accessibilityLabel("장바구니 화면으로 이동")

            Spacer()
        }
        .navigationBarTitle("메뉴 선택", displayMode: .inline)
        .sheet(item: $selectedMenuDetail) { menuItem in
            // 상세 Sheet
            MenuDetailView(menuItem: menuItem, cartItems: $cartItems)
                .environmentObject(accessibilitySettings)
        }
    }
}

// MARK: - 메뉴 상세 정보 모델
struct MenuItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Int
    let description: String
    let imageName: String
}

// MARK: - 메뉴 상세 보기 화면 (Sheet)
struct MenuDetailView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    let menuItem: MenuItem
    @Binding var cartItems: [String]

    func dynamicFont(_ baseSize: CGFloat) -> Font {
        let size = accessibilitySettings.isLargeText ? baseSize + 4 : baseSize
        return .system(size: size)
    }

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 16) {
            Text("메뉴 상세 정보")
                .font(dynamicFont(24)).bold()
                .padding(.top)

            Image(systemName: menuItem.imageName)
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)

            Text(menuItem.name)
                .font(dynamicFont(22)).bold()

            Text("가격: ₩\(menuItem.price)")
                .font(dynamicFont(18))

            Text(menuItem.description)
                .font(dynamicFont(16))
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScalableButton {
                cartItems.append(menuItem.name)
            } label: {
                Text("장바구니에 담기")
                    .font(dynamicFont(20)).bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(accessibilitySettings.isHighContrast ? Color.black : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            ScalableButton {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("닫기")
                    .font(dynamicFont(18)).bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(accessibilitySettings.isHighContrast ? Color.black : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

// MARK: - 장바구니 화면
struct CartView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    @State var cartItems: [String]

    func dynamicFont(_ baseSize: CGFloat) -> Font {
        let size = accessibilitySettings.isLargeText ? baseSize + 4 : baseSize
        return .system(size: size)
    }

    var body: some View {
        VStack {
            Text("장바구니 화면")
                .font(dynamicFont(28)).bold()
                .accessibilityAddTraits(.isHeader)
                .padding()

            if cartItems.isEmpty {
                Text("장바구니가 비어 있습니다.")
                    .font(dynamicFont(20))
                    .padding()
            } else {
                List {
                    ForEach(cartItems, id: \.self) { item in
                        Text(item)
                            .font(dynamicFont(20))
                    }
                    .onDelete { indexSet in
                        cartItems.remove(atOffsets: indexSet)
                    }
                }

                Text("총합: ₩\(cartItems.count * 5000)")
                    .font(dynamicFont(18)).bold()
                    .padding()

                // 결제하기 버튼
                NavigationLink(destination: PaymentView(totalPrice: cartItems.count * 5000)
                    .environmentObject(accessibilitySettings)) {
                    Text("결제하기")
                        .font(dynamicFont(22)).bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(accessibilitySettings.isHighContrast ? Color.black : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .navigationBarTitle("장바구니", displayMode: .inline)
    }
}

// MARK: - 결제 화면
struct PaymentView: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    let totalPrice: Int

    @State private var paymentStatus: String? = nil

    func dynamicFont(_ baseSize: CGFloat) -> Font {
        let size = accessibilitySettings.isLargeText ? baseSize + 4 : baseSize
        return .system(size: size)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("결제 진행 화면")
                .font(dynamicFont(28)).bold()
                .accessibilityAddTraits(.isHeader)
                .padding(.top)

            Text("총 결제 금액: ₩\(totalPrice)")
                .font(dynamicFont(22))

            // 예시: 큰 버튼 2개 (카드/현금)
            HStack(spacing: 40) {
                ScalableButton {
                    simulatePayment(success: true)
                } label: {
                    VStack {
                        Image(systemName: "creditcard.fill")
                            .resizable()
                            .frame(width: 50, height: 35)
                        Text("카드 결제")
                            .font(dynamicFont(18)).bold()
                    }
                    .padding()
                    .background(accessibilitySettings.isHighContrast ? Color.black : Color.blue.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                }

                ScalableButton {
                    simulatePayment(success: false)
                } label: {
                    VStack {
                        Image(systemName: "banknote.fill")
                            .resizable()
                            .frame(width: 50, height: 35)
                        Text("현금 결제")
                            .font(dynamicFont(18)).bold()
                    }
                    .padding()
                    .background(accessibilitySettings.isHighContrast ? Color.black : Color.green.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                }
            }

            if let paymentStatus = paymentStatus {
                Text(paymentStatus)
                    .font(dynamicFont(20)).bold()
                    .padding()
                    .foregroundColor(paymentStatus.contains("성공") ? .green : .red)
                    .accessibilityLabel("결제 결과: \(paymentStatus)")
            }

            Spacer()
        }
        .padding(.horizontal)
        .navigationBarTitle("결제", displayMode: .inline)
    }

    func simulatePayment(success: Bool) {
        if success {
            paymentStatus = "결제 성공! 주문이 완료되었습니다."
        } else {
            paymentStatus = "결제 실패! 다시 시도해주세요."
        }
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
- [주문하기], [직원 호출], [음성으로 주문하기] 버튼을 눌러주세요.
- 예시 이미지는 실제 정보가 아니니 헷갈리지 마세요.
- 결제 시 오류가 발생하면 화면에 나타나는 안내 문구를 참고해주세요.
- 화면에 더 많은 정보가 필요하면 아래로 스크롤하세요.
- [접근성 설정]에서 어린이/장애인/노인 모드를 위한 여러 옵션(글자 크게, 고대비 등)을 사용하실 수 있습니다.
- 메뉴에 대한 상세 정보는 메뉴를 탭하면 보실 수 있습니다. (영양, 알레르기 정보 등)
""")
                    .font(dynamicFont(18))

                Spacer()
            }
            .padding()
        }
        .navigationBarTitle("도움말", displayMode: .inline)
    }
}

// MARK: - 프리뷰
struct KioskHomeView_Previews: PreviewProvider {
    static var previews: some View {
        KioskHomeView()
    }
}
