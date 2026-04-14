import SwiftUI

// 模擬你的 Task 資料結構，加入一個 isShared 屬性
struct DummyTask: Identifiable {
    let id = UUID()
    var title: String
    var isShared: Bool
}

struct ShareView_new: View {
    @EnvironmentObject var authManager: AuthenticationManager
    // @EnvironmentObject var shareManager: ShareManager
    
    @State private var inviteEmail: String = ""
    
    // 模擬：使用者所有的任務清單
    @State private var allTasks: [DummyTask] = [
        DummyTask(title: "Math Homework", isShared: true),
        DummyTask(title: "History Essay", isShared: true),
        DummyTask(title: "Costco Shopping", isShared: false),
        DummyTask(title: "Get off work on time", isShared: false)
    ]

    // MARK: - 自定義顏色
    let appBackground = Color(red: 0.97, green: 0.96, blue: 0.94) // 米白底色
    let cardBackground = Color.white
    let primaryAccent = Color.cyan // 亮藍綠色強調色
    let inputBackground = Color(red: 0.94, green: 0.93, blue: 0.91)

    var body: some View {
        ZStack {
            appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    
                    // ==========================================
                    // MARK: - 第一部分：Friends
                    // ==========================================
                    VStack(spacing: 20) {
                        // 1. Friends 列表
                        CardView(title: "Friends") {
                            // 這裡放你的 shareManager.friends 邏輯
                            // 模擬畫面：傳入 streak 數值
                            VStack(spacing: 16) {
                                FriendRow(name: "Apple Lin", email: "apple@example.com", streak: 12)
                                FriendRow(name: "Bob Chen", email: "bob@example.com", streak: 5)
                            }
                        }

                        // 2. Invite Friends 區塊
                        CardView(title: "Invite Friends") {
                            HStack {
                                CustomTextField(placeholder: "friend@example.com", text: $inviteEmail)
                                
                                Button(action: { sendInvite() }) {
                                    Text("Invite")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .frame(height: 44)
                                        .background(
                                            inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                            ? Color.gray.opacity(0.3) : primaryAccent
                                        )
                                        .clipShape(Capsule())
                                }
                                .disabled(inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }

                    // ==========================================
                    // MARK: - 第二部分：Shared Tasks
                    // ==========================================
                    VStack(spacing: 20) {
                        CardView(title: "Sharing Tasks") {
                            Text("Select tasks you want to share with your friends.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)
                            
                            VStack(spacing: 0) {
                                ForEach($allTasks) { $task in
                                    HStack {
                                        Text(task.title)
                                            .font(.body)
                                            .foregroundColor(task.isShared ? .primary : .secondary)
                                        
                                        Spacer()
                                        
                                        // 客製化的 Checkbox
                                        Button(action: {
                                            withAnimation(.spring()) {
                                                task.isShared.toggle()
                                            }
                                        }) {
                                            Image(systemName: task.isShared ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 22))
                                                .foregroundColor(task.isShared ? primaryAccent : Color.gray.opacity(0.4))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 12)
                                    
                                    if task.id != allTasks.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer().frame(height: 100) // 底部留白避開 TabBar
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func sendInvite() {
        // 實作寄送邀請邏輯
        print("Invited: \(inviteEmail)")
        inviteEmail = ""
    }
}

// MARK: - 可重複使用的 UI 元件

struct FriendRow: View {
    var name: String
    var email: String
    var streak: Int // 新增：累計完成任務數
    
    var body: some View {
        HStack {
            // 圓形頭像佔位符
            Circle()
                .fill(Color.cyan.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.cyan)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(email)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 新增：火焰與累計完成任務數徽章
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.subheadline)
                Text("\(streak)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15)) // 淡淡的橘色背景，讓火焰徽章更突出
            .clipShape(Capsule())
        }
    }
}

struct CardView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            
            content
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
    }
}

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color(red: 0.94, green: 0.93, blue: 0.91))
            .cornerRadius(12)
    }
}
