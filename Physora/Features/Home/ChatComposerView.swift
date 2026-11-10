import PhotosUI
import SwiftUI
import UIKit

struct ChatComposerView: View {
    @Binding var text: String
    @Binding var photos: [TaskPhoto]
    @FocusState.Binding var isFocused: Bool

    let isSending: Bool
    let onSend: () -> Void

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var photoError: String?
    @State private var showingPhotoSources = false
    @State private var showingLibrary = false
    @State private var showingCamera = false

    private let characterLimit = 4_000
    private let photoLimit = 4

    private var canSend: Bool {
        !isSending
            && (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !photos.isEmpty)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !photos.isEmpty {
                photoStrip
            }

            HStack(alignment: .bottom, spacing: 9) {
                photoPickerButton

                TextField("Задача или фото…", text: $text, axis: .vertical)
                    .font(.body)
                    .lineLimit(1...5)
                    .focused($isFocused)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSend { onSend() }
                    }
                    .accessibilityLabel("Условие задачи")

                sendButton
            }
            .padding(.leading, 8)
            .padding(.trailing, 6)
            .padding(.vertical, 7)
            .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
            )

            if let photoError {
                Text(photoError)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
            } else if !photos.isEmpty {
                Text("Фотографии распознает DeepSeek Flash")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 10)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Color.physoraBackground)
        .confirmationDialog(
            "Добавить фотографию",
            isPresented: $showingPhotoSources,
            titleVisibility: .visible
        ) {
            Button("Медиатека") {
                showingLibrary = true
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Камера") {
                    showingCamera = true
                }
            }
            Button("Отмена", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showingLibrary,
            selection: $pickerItems,
            maxSelectionCount: max(1, photoLimit - photos.count),
            matching: .images,
            photoLibrary: .shared()
        )
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                addCameraImage(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await loadPhotos(newItems) }
        }
        .onChange(of: text) { _, newValue in
            if newValue.count > characterLimit {
                text = String(newValue.prefix(characterLimit))
            }
        }
    }

    private var photoPickerButton: some View {
        Button {
            showingPhotoSources = true
        } label: {
            ZStack {
                if isLoadingPhotos {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 17, weight: .medium))
                }
            }
            .foregroundStyle(Color.primary)
            .frame(width: 38, height: 38)
            .background(Color.physoraSurfaceMuted, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(photos.count >= photoLimit || isSending || isLoadingPhotos)
        .accessibilityLabel("Прикрепить фотографию задачи")
    }

    private var sendButton: some View {
        Button {
            guard canSend else { return }
            onSend()
        } label: {
            ZStack {
                Circle()
                    .fill(canSend ? Color.primary : Color.physoraSurfaceMuted)
                    .frame(width: 38, height: 38)
                if isSending {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color(uiColor: .systemBackground))
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(canSend ? Color(uiColor: .systemBackground) : Color.secondary)
                }
            }
        }
        .buttonStyle(PressableScaleButtonStyle())
        .disabled(!canSend)
        .accessibilityLabel("Отправить задачу")
    }

    private var photoStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(photos) { photo in
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if let image = photo.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color.physoraSurfaceMuted
                            }
                        }
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .strokeBorder(Color.physoraStroke, lineWidth: 1)
                        )

                        Button {
                            photos.removeAll { $0.id == photo.id }
                            Haptics.light()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color(uiColor: .systemBackground))
                                .frame(width: 18, height: 18)
                                .background(Color.primary, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .offset(x: 5, y: -5)
                        .disabled(isSending)
                        .accessibilityLabel("Удалить фотографию")
                    }
                    .padding(.top, 5)
                    .padding(.trailing, 5)
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 3)
    }

    @MainActor
    private func addCameraImage(_ image: UIImage) {
        guard photos.count < photoLimit else { return }
        guard let photo = TaskPhoto.compressed(from: image) else {
            photoError = "Не удалось подготовить фотографию. Попробуйте ещё раз."
            return
        }
        photoError = nil
        photos.append(photo)
        Haptics.light()
    }

    @MainActor
    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        isLoadingPhotos = true
        photoError = nil
        let available = max(0, photoLimit - photos.count)
        for item in items.prefix(available) {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    photoError = "Не удалось прочитать выбранное изображение."
                    continue
                }
                guard let photo = TaskPhoto.compressed(from: data) else {
                    photoError = "Фото слишком большое или имеет неподдерживаемый формат."
                    continue
                }
                photos.append(photo)
            } catch {
                photoError = "Не удалось загрузить фотографию."
            }
        }
        pickerItems = []
        isLoadingPhotos = false
        Haptics.light()
    }
}
