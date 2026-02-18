//
//  HomeView.swift
//  UserAuthentication
//
//  Created by David Estrella on 1/24/26.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isPresentingPhotoPicker = false
    @State private var selectedUIImage: UIImage?
    @State private var isUpdatingPhoto = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoSourceMenu = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 24) {
                    Spacer()

                    // User Profile Section
                    VStack(spacing: 16) {
                        // Profile Image (tappable to change)
                        ZStack {
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
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )

                            // Camera overlay icon
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                        .padding(6)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .padding(4)
                                }
                            }
                            .frame(width: 100, height: 100)
                        }
                        .contentShape(Rectangle())
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
                        VStack(spacing: 8) {
                            if let displayName = authManager.currentUser?.displayName {
                                Text(displayName)
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                                .padding(.top, 4)
                            }
                        }
                    }

                    Spacer()

                    // User Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account Details")
                            .font(.headline)

                        VStack(spacing: 12) {
                            DetailRow(
                                icon: "person.fill",
                                title: "User ID",
                                value: authManager.currentUser?.id ?? "N/A"
                            )

                            Divider()

                            DetailRow(
                                icon: "envelope.fill",
                                title: "Email",
                                value: authManager.currentUser?.email ?? "Not provided"
                            )

                            Divider()

                            DetailRow(
                                icon: "shield.fill",
                                title: "Auth Provider",
                                value: providerName(for: authManager.currentUser?.authProvider ?? AppAuthProvider.email)
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Spacer()

                    // Sign Out Button
                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .foregroundStyle(.red)
                        .cornerRadius(8)
                    }

                    Spacer()
                }
                if isUpdatingPhoto {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Updating photo...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { selectedUIImage = nil }
            .onChange(of: authManager.currentUser?.photoURL) { _ in
                selectedUIImage = nil
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Edit") {
                        EditProfileView()
                            .environmentObject(authManager)
                    }
                }
            }
        }
    }

    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundStyle(.blue)
    }

    @ViewBuilder
    private func providerIcon(for provider: AppAuthProvider) -> some View {
        switch provider {
        case .apple:
            Image(systemName: "apple.logo")
        case .google:
            Image(systemName: "g.circle.fill")
        case .email:
            Image(systemName: "envelope.fill")
        }
    }

    private func providerName(for provider: AppAuthProvider) -> String {
        switch provider {
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        case .email:
            return "Email"
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.subheadline)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}

