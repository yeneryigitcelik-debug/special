import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.eliteBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: EliteSpacing.xl) {
                        // Photos section
                        VStack(alignment: .leading, spacing: EliteSpacing.sm) {
                            sectionHeader("Photos")

                            EditablePhotoGrid(
                                photoURLs: $viewModel.photoURLs,
                                onAddPhoto: { showPhotoPicker = true },
                                onRemovePhoto: { index in
                                    viewModel.removePhoto(at: index)
                                }
                            )
                        }

                        // Basic info
                        VStack(alignment: .leading, spacing: EliteSpacing.md) {
                            sectionHeader("About You")

                            EliteTextField(
                                placeholder: "Display Name",
                                text: $viewModel.displayName,
                                icon: "person"
                            )

                            EliteTextField(
                                placeholder: "Title / Profession",
                                text: $viewModel.title,
                                icon: "briefcase"
                            )

                            EliteTextField(
                                placeholder: "City",
                                text: $viewModel.locationCity,
                                icon: "mappin"
                            )

                            VStack(alignment: .leading, spacing: EliteSpacing.xs) {
                                Text("Bio")
                                    .font(EliteFont.labelMedium())
                                    .foregroundColor(.eliteTextSecondary)

                                TextEditor(text: $viewModel.bio)
                                    .font(EliteFont.bodyMedium())
                                    .foregroundColor(.eliteTextPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 100)
                                    .padding(EliteSpacing.sm)
                                    .background(Color.eliteSurface)
                                    .cornerRadius(EliteRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: EliteRadius.medium)
                                            .strokeBorder(Color.eliteDivider, lineWidth: 1)
                                    )
                                    .tint(.eliteAccent)
                                    .onChange(of: viewModel.bio) { _, newValue in
                                        if newValue.count > 300 {
                                            viewModel.bio = String(newValue.prefix(300))
                                        }
                                    }

                                HStack {
                                    Spacer()
                                    Text("\(viewModel.bio.count)/300")
                                        .font(EliteFont.caption())
                                        .foregroundColor(viewModel.bio.count > 300 ? .eliteError : .eliteTextTertiary)
                                }
                            }
                        }

                        // Interests
                        VStack(alignment: .leading, spacing: EliteSpacing.md) {
                            sectionHeader("Interests")

                            TagChipFlow(
                                tags: ProfileViewModel.popularTags,
                                selectedTags: Set(viewModel.interestTags)
                            ) { tag in
                                viewModel.toggleTag(tag)
                            }
                        }
                    }
                    .padding(.horizontal, EliteSpacing.lg)
                    .padding(.vertical, EliteSpacing.lg)
                    .padding(.bottom, 80)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(EliteFont.labelLarge())
                        .foregroundColor(.eliteTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            dismiss()
                        }
                    }
                    .font(EliteFont.labelLarge())
                    .foregroundColor(.eliteAccent)
                    .disabled(viewModel.isSaving)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.uploadPhoto(data: data)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(EliteFont.labelSmall())
            .foregroundColor(.eliteTextTertiary)
            .tracking(1.5)
    }
}
