//
//  PhotosPickerItemExtension.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-08-01.
//

import PhotosUI
import SwiftUI

extension PhotosPickerItem {
    func getData(completionHandler: @escaping (_ result: Result<Data, Error>) -> Void) {
        self.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data ?? Data()))
            case .failure(let failure):
                completionHandler(.failure(failure))
            }
        }
    }
    
    func getFilename(completionHandler: @escaping (_ result: Result<String, Error>) -> Void) {
        self.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let contentType = self.supportedContentTypes.first {
                    let fileName = data?.MD5 ?? UUID().uuidString
                    let preferredFilenameExtension = contentType.preferredFilenameExtension ?? ""
                    if preferredFilenameExtension.isEmpty {
                        completionHandler(.success(fileName))
                    } else {
                        completionHandler(.success("\(fileName).\(preferredFilenameExtension)"))
                    }
                }
            case .failure(let failure):
                completionHandler(.failure(failure))
            }
        }
    }
}
