import SwiftUI
import PhotosUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var user: User?
    @Published var displayName = ""
    @Published var bio = ""
    @Published var title = ""
    @Published var locationCity = ""
    @Published var interestTags: [String] = []
    @Published var photoURLs: [String] = []
    @Published var errorMessage: String?
    @Published var isSaving = false

    enum ViewState {
        case idle, loading, loaded, error
    }

    private let profileService = ProfileService()

    func load() async {
        state = .loading
        do {
            let profile = try await profileService.fetchCurrentProfile()
            self.user = profile
            self.displayName = profile.displayName
            self.bio = profile.bio ?? ""
            self.title = profile.title ?? ""
            self.locationCity = profile.locationCity ?? ""
            self.interestTags = profile.interestTags
            self.photoURLs = profile.photoURLs
            state = .loaded
        } catch {
            errorMessage = error.localizedDescription
            state = .error
        }
    }

    func save() async {
        isSaving = true
        do {
            try await profileService.updateProfile(
                displayName: displayName,
                bio: bio.isEmpty ? nil : bio,
                title: title.isEmpty ? nil : title,
                interestTags: interestTags,
                locationCity: locationCity.isEmpty ? nil : locationCity
            )

            try await profileService.updatePhotoURLs(photoURLs)

            await load()
            isSaving = false
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }

    func uploadPhoto(data: Data) async {
        do {
            let url = try await profileService.uploadPhoto(data: data)
            photoURLs.append(url)
        } catch {
            errorMessage = "Failed to upload photo"
        }
    }

    func removePhoto(at index: Int) {
        guard index < photoURLs.count else { return }
        photoURLs.remove(at: index)
    }

    func movePhoto(from source: IndexSet, to destination: Int) {
        photoURLs.move(fromOffsets: source, toOffset: destination)
    }

    func toggleTag(_ tag: String) {
        if interestTags.contains(tag) {
            interestTags.removeAll { $0 == tag }
        } else {
            interestTags.append(tag)
        }
    }

    static let popularTags = [
        "Art", "Travel", "Wine", "Architecture", "Photography",
        "Fine Dining", "Fashion", "Music", "Film", "Literature",
        "Fitness", "Yoga", "Sailing", "Golf", "Tennis",
        "Entrepreneurship", "Tech", "Design", "Nature", "Cooking"
    ]
}
