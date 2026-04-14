import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isPresentingPhotoPicker = false
    @State private var selectedUIImage: UIImage?
    @State private var isUpdatingPhoto = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoSourceMenu = false

    // MARK: - 自定義顏色 (保持與 Dashboard/Share 一致)
    let appBackground = Color(red: 0.97, green: 0.96, blue: 0.94) // 米白底色
    let cardBackground = Color.white
    let primaryAccent = Color.cyan // 統一的亮藍綠色強調色

    var body: some View {
        NavigationStack {
            ZStack {
                // 全域背景色
                appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) { // 加大區塊間距
                        
                        // ==========================================
                        // MARK: - 1. User Profile Header
                        // ==========================================
                        VStack(spacing: 16) {
                            // Profile Image (tappable to change)
                            ZStack(alignment: .bottomTrailing) {
                                Group {
                                    if let image = selectedUIImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                    } else if let photoURL = authManager.currentUser?.photoURL {
                                        AsyncImage(url: photoURL) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            case .failure:
                                                defaultProfileImage
                                            @unknown default:
                                                defaultProfileImage
                                            }
                                        }
                                    } else {
                                        defaultProfileImage
                                    }
                                }
                                .frame(width: 120, height: 120) // 依照截圖稍微放大一點
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4)) // 加入白色粗邊框
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)

                                // 仿照截圖的相機小圖示 (右下角)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: .black.opacity(0.15), radius: 3)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.black)
                                    )
                                    .offset(x: 0, y: 0) // 微調位置讓它剛好卡在邊緣
                            }
                            .contentShape(Circle())
                            .onTapGesture {
                                showPhotoSourceMenu = true
                            }
                            .confirmationDialog("Change profile photo", isPresented: $showPhotoSourceMenu, titleVisibility: .visible) {
                                Button("Choose from Library") { isPresentingPhotoPicker = true }
                                Button("Remove Photo", role: .destructive) {
                                    isUpdatingPhoto = true
                                    Task {
                                        await authManager.removePhoto()
                                        await MainActor.run {
                                            selectedUIImage = nil
                                            isUpdatingPhoto = false
                                        }
                                    }
                                }
                                Button("Cancel", role: .cancel) {}
                            }
                            .photosPicker(isPresented: $isPresentingPhotoPicker, selection: $photoPickerItem, matching: .images)
                            .onChange(of: photoPickerItem) { oldItem, newItem in
                                guard let newItem else { return }
                                Task {
                                    if let data = try? await newItem.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        await MainActor.run {
                                            selectedUIImage = uiImage
                                            isUpdatingPhoto = true
                                        }
                                        await authManager.updatePhoto(with: uiImage)
                                        await MainActor.run { isUpdatingPhoto = false }
                                    }
                                }
                            }

                            // User Info
                            VStack(spacing: 6) {
                                if let displayName = authManager.currentUser?.displayName {
                                    Text(displayName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                } else {
                                    Text("Peng-Lin Chung") // Fallback
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }

                                if let email = authManager.currentUser?.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                // Auth Provider Badge
                                if let provider = authManager.currentUser?.authProvider {
                                    HStack(spacing: 6) {
                                        providerIcon(for: provider)
                                            .font(.caption)
                                        Text("Signed in with \(providerName(for: provider))")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.05)) // 淡淡的灰底
                                    .clipShape(Capsule())
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.top, 20)

                        // ==========================================
                        // MARK: - 2. User Details Card
                        // ==========================================
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Details")
                                .font(.headline)
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                DetailRow(
                                    icon: "person.fill",
                                    title: "User ID",
                                    value: authManager.currentUser?.id ?? "N/A",
                                    accentColor: primaryAccent
                                )
                                
                                Divider().padding(.leading, 44) // 讓分隔線避開 Icon

                                DetailRow(
                                    icon: "envelope.fill",
                                    title: "Email",
                                    value: authManager.currentUser?.email ?? "Not provided",
                                    accentColor: primaryAccent
                                )

                                Divider().padding(.leading, 44)

                                DetailRow(
                                    icon: "shield.fill",
                                    title: "Auth Provider",
                                    value: providerName(for: authManager.currentUser?.authProvider ?? .email),
                                    accentColor: primaryAccent
                                )
                            }
                            .padding(.vertical, 8)
                            .background(cardBackground)
                            .cornerRadius(24) // 統一的大圓角
                            // .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)

                        // ==========================================
                        // MARK: - 3. Sign Out Button
                        // ==========================================
                        Button(action: {
                            authManager.signOut()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .font(.body.weight(.medium))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(cardBackground)
                            .cornerRadius(16)
                            // .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)

                        Spacer().frame(height: 100) // 避開下方 TabBar
                    }
                }
                
                // MARK: - 讀取中遮罩
                if isUpdatingPhoto {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Updating photo...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { selectedUIImage = nil }
            .onChange(of: authManager.currentUser?.photoURL) { _ in
                selectedUIImage = nil
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: Text("Edit Profile View")) { // 這裡換回你的 EditProfileView()
                        Text("Edit")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.05), radius: 5)
                    }
                }
            }
        }
    }

    // MARK: - 輔助 Functions 與 Views
    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(primaryAccent.opacity(0.5)) // 換成主題色
    }

    @ViewBuilder
    private func providerIcon(for provider: AuthProvider) -> some View {
        switch provider {
        case .apple:  Image(systemName: "apple.logo")
        case .google: Image(systemName: "g.circle.fill")
        case .email:  Image(systemName: "envelope.fill")
        }
    }

    private func providerName(for provider: AuthProvider) -> String {
        switch provider {
        case .apple:  return "Apple"
        case .google: return "Google"
        case .email:  return "Email"
        }
    }
}

// MARK: - DetailRow 元件調整
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var accentColor: Color = .blue

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(accentColor)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
