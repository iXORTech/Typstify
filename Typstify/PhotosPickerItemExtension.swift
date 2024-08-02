//
//  PhotosPickerItemExtension.swift
//  Typstify
//
//  Created by Cubik65536 on 2024-08-01.
//

import PhotosUI
import SwiftUI

extension PhotosPickerItem {
    func writeToDirectory(directory: URL, completionHandler: @escaping (_ result: Result<URL, Error>) -> Void) {
       self.loadTransferable(type: Data.self) { result in
           switch result {
           case .success(let data):
               if let contentType = self.supportedContentTypes.first {
                   let url = directory.appendingPathComponent("\(UUID().uuidString).\(contentType.preferredFilenameExtension ?? "")")
                   
                   if let data = data {
                       do {
                           try data.write(to: url)
                           completionHandler(.success(url))
                       } catch {
                           completionHandler(.failure(error))
                       }
                   }
               }
           case .failure(let failure):
               completionHandler(.failure(failure))
           }
       }
    }
}
