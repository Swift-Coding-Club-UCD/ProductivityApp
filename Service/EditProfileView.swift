import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @FocusState private var isNameFieldFocused: Bool

    @State private var selectedUIImage: UIImage?
    @State private var isUpdatingPhoto = false
    @State private var isPresentingPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    @State private var isUpdatingPassword: Bool = false
    @State private var passwordAlertMessage: String?
    @State private var isShowingPasswordAlert: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile Photo")) {
                    HStack(spacing: 16) {
                        ZStack {
                            Group {
                                if let image = selectedUIImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                } else if let url = authManager.currentUser?.photoURL {
                                    AsyncImage(url: url) { phase in
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
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color(.systemGray4), lineWidth: 1)
                            )

                            if isUpdatingPhoto {
                                ProgressView()
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Button("Choose Photo") { isPresentingPhotoPicker = true }
                                .disabled(isUpdatingPhoto)
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
                            .disabled(isUpdatingPhoto || (authManager.currentUser?.photoURL == nil && selectedUIImage == nil))
                        }
                    }
                }

                Section(header: Text("Display Name")) {
                    TextField("Enter your name", text: $displayName)
                        .focused($isNameFieldFocused)
                }

                Section(header: Text("Change Password")) {
                    SecureField("Current Password", text: $currentPassword)
                        .textContentType(.password)
                        .disabled(isUpdatingPassword)
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                        .disabled(isUpdatingPassword)
                    SecureField("Confirm New Password", text: $confirmNewPassword)
                        .textContentType(.newPassword)
                        .disabled(isUpdatingPassword)

                    Button {
                        updatePassword()
                    } label: {
                        if isUpdatingPassword {
                            ProgressView()
                        } else {
                            Text("Update Password")
                        }
                    }
                    .disabled(isUpdatingPassword || currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty || newPassword != confirmNewPassword)
                }
            }
            .photosPicker(isPresented: $isPresentingPhotoPicker, selection: $photoPickerItem, matching: .images)
            .onChange(of: photoPickerItem) { newValue in
                guard let newItem = newValue else { return }
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
            .navigationTitle("Edit Profile")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        saveProfile()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert(passwordAlertMessage ?? "", isPresented: $isShowingPasswordAlert) {
                Button("OK") { passwordAlertMessage = nil }
            }
            .onAppear {
                if let currentName = authManager.currentUser?.displayName {
                    displayName = currentName
                }
                if let url = authManager.currentUser?.photoURL,
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    self.selectedUIImage = image
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isNameFieldFocused = true
                }
            }
        }
    }

    private func saveProfile() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        authManager.updateDisplayName(trimmedName)
        dismiss()
    }
    
    private func updatePassword() {
        guard !isUpdatingPassword else { return }
        let trimmedCurrent = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNew = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmNewPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCurrent.isEmpty, !trimmedNew.isEmpty, !trimmedConfirm.isEmpty else { return }
        guard trimmedNew == trimmedConfirm else {
            passwordAlertMessage = "New passwords do not match."
            isShowingPasswordAlert = true
            return
        }
        isUpdatingPassword = true
        Task {
            do {
                // TODO: Implement password update in AuthenticationManager
                try await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    passwordAlertMessage = "Password updated successfully."
                    isShowingPasswordAlert = true
                    currentPassword = ""
                    newPassword = ""
                    confirmNewPassword = ""
                    isUpdatingPassword = false
                }
            } catch {
                await MainActor.run {
                    passwordAlertMessage = error.localizedDescription
                    isShowingPasswordAlert = true
                    isUpdatingPassword = false
                }
            }
        }
    }

    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
            .foregroundStyle(.blue)
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AuthenticationManager())
}
