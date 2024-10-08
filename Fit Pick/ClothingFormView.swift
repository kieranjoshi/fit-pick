//
//  ClothingFormView.swift
//  Fit Pick
//
//  Created by Kieran Joshi on 8/19/24.
//

import SwiftUI
import PhotosUI

@MainActor
final class PhotoPickerViewModel: ObservableObject {
    
    @Published private(set) var selectedImage: UIImage? = nil
    @Published var selectedImageData: Data? = nil
    @Published var imageSelection: PhotosPickerItem? = nil{
        didSet{
            setImage(from: imageSelection)
        }
    }
    
    private func setImage(from selection: PhotosPickerItem?) {
        guard let selection else { return }
        
        Task {
            if let data = try? await selection.loadTransferable(type: Data.self) {
                selectedImageData = data
                if let uiImage = UIImage(data: data){
                    selectedImage = uiImage
                    return
                }
            }
        }
    }
    
    func removeImage() {
        selectedImage = nil
        selectedImageData = nil
        imageSelection = nil
    }

}

struct ClothingFormView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    @State private var selectedClothingType: ClothingType = .shirt
    @State private var brand: String = ""
    @StateObject private var viewModel = PhotoPickerViewModel()
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select a Photo")) {
                    PhotosPicker(selection: $viewModel.imageSelection, matching: .images){
                        Label("Add Image", systemImage: "photo")
                            .foregroundStyle(.blue)
                        
                    }
                    
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200,alignment: .center)
                            .cornerRadius(10)
                        
                        Button(role: .destructive){
                            withAnimation{
                                viewModel.removeImage()
                            }
                        } label: {
                            Label("Remove Image", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                if viewModel.selectedImage != nil {
                    Section(header: Text("Info")){
                        TextField("Brand", text: $brand)
                            .textInputAutocapitalization(.words)
                        Picker(selection: $selectedClothingType, label: Text("Clothing Type")) {
                            ForEach(ClothingType.allCases) { clothingtype in
                                Text(clothingtype.title).tag(clothingtype)
                            }
                        }
                    }
                }
    
                Section {
                    if let data = viewModel.selectedImageData {
                        Button("Submit") {
                            let item = ClothingItem(image: data, type: selectedClothingType, brand: brand)
                            context.insert(item)
                            dismiss()
                        }
                    }
                    else{
                        Button("Submit") {
                            
                        }.foregroundStyle(.gray)
                    }
                    
                }
            }
            .navigationBarTitle("Add Clothing")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

#Preview {
    ClothingFormView()
        .modelContainer(for:[ClothingItem.self], inMemory: true)
}
