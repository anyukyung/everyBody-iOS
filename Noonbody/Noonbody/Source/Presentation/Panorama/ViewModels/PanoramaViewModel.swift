//
//  PanoramaViewModel.swift
//  everyBody-iOS
//
//  Created by kong on 2021/11/02.
//

import RxSwift
import RxCocoa

final class PanoramaViewModel {
    private let panoramaUseCase: PanoramaUseCase
    
    struct Input {
        let cameraViewDidDisappear: Observable<Void>
        let albumId: Int
        let albumNameTextField: Observable<String>
        let deletePictureData: Observable<[Int: Int]>
        let deletePictureButtonControlEvent: ControlEvent<Void>
        let deleteAlbumButtonControlEvent: ControlEvent<Void>
        let renameButtonControlEvent: ControlEvent<Void>
    }
    
    struct Output {
        let album: Driver<Album?>
        let canRename: Driver<Bool>
        let renamedAlbum: Driver<String?>
        let deletePictureCount: Driver<Int>
        let deletePictureStatusCode: Driver<Int>
        let deleteAlbumStatusCode: Driver<Int>
    }
    
    init(panoramaUseCase: PanoramaUseCase) {
        self.panoramaUseCase = panoramaUseCase
    }
    
    func transform(input: Input) -> Output {
        
        let pictureData = input.deletePictureData
            .flatMap {
                Observable.from($0.values)
            }
            .share()
        
        let album = input.cameraViewDidDisappear
            .flatMap { _ in
                self.panoramaUseCase.getAlbum(albumId: input.albumId) }
            .map { $0 }
            .share()
        
        let renameResponse = input.renameButtonControlEvent
            .withLatestFrom(input.albumNameTextField)
            .map { name in
                return AlbumRequestModel(name: name)
            }
            .flatMap { request in
                self.panoramaUseCase.renameAlbum(albumId: input.albumId, request: request)
            }
            .share()
        
        let deletePictureResponse = input.deletePictureButtonControlEvent
            .withLatestFrom(pictureData)
            .flatMap { pictureId in
                self.panoramaUseCase.deletePicture(pictureId: pictureId)
            }
            .share()
        
        let deleteAlbumResponse = input.deleteAlbumButtonControlEvent
            .flatMap {
                self.panoramaUseCase.deleteAlbum(albumId: input.albumId)
            }.map { $0 }
            .share()
        
        let data = album
            .compactMap { $0 }
            .map { response -> Album in
                return response
            }.asDriver(onErrorJustReturn: nil)
        
        let canRename = input.albumNameTextField
            .map { name in
                return !name.isEmpty
            }.asDriver(onErrorJustReturn: false)
        
        let renamedAlbum = renameResponse
            .map { response -> String in
                return response.name
            }.asDriver(onErrorJustReturn: nil)
        
        let deletePictureCount = input.deletePictureData
            .map { data in
                return data.count
            }.asDriver(onErrorJustReturn: 0)
        
        let deletePictureStatusCode = deletePictureResponse
            .compactMap { $0 }
            .map { result -> Int in
                return result
            }.asDriver(onErrorJustReturn: 404)
        
        let deleteAlbumStatusCode = deleteAlbumResponse
            .compactMap { $0 }
            .map { response -> Int in
                return response
            }.asDriver(onErrorJustReturn: 404)
        
        return Output(album: data, canRename: canRename, renamedAlbum: renamedAlbum, deletePictureCount: deletePictureCount, deletePictureStatusCode: deletePictureStatusCode, deleteAlbumStatusCode: deleteAlbumStatusCode)
    }
}
