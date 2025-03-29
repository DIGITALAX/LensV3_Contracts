import {
  CollectionDeleted as CollectionDeletedEvent,
  GalleryCreated as GalleryCreatedEvent,
  GalleryDeleted as GalleryDeletedEvent,
  GalleryEdited as GalleryEditedEvent,
  GalleryUpdated as GalleryUpdatedEvent,
  PostIdConnected as PostIdConnectedEvent
} from "../generated/AutographCollections/AutographCollections"
import {
  CollectionDeleted,
  GalleryCreated,
  GalleryDeleted,
  GalleryEdited,
  GalleryUpdated,
  PostIdConnected
} from "../generated/schema"

export function handleCollectionDeleted(event: CollectionDeletedEvent): void {
  let entity = new CollectionDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.collectionId = event.params.collectionId
  entity.galleryId = event.params.galleryId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleGalleryCreated(event: GalleryCreatedEvent): void {
  let entity = new GalleryCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.designer = event.params.designer
  entity.galleryId = event.params.galleryId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleGalleryDeleted(event: GalleryDeletedEvent): void {
  let entity = new GalleryDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.designer = event.params.designer
  entity.galleryId = event.params.galleryId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleGalleryEdited(event: GalleryEditedEvent): void {
  let entity = new GalleryEdited(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.uri = event.params.uri
  entity.galleryId = event.params.galleryId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleGalleryUpdated(event: GalleryUpdatedEvent): void {
  let entity = new GalleryUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.designer = event.params.designer
  entity.galleryId = event.params.galleryId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePostIdConnected(event: PostIdConnectedEvent): void {
  let entity = new PostIdConnected(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.postId = event.params.postId
  entity.collectionId = event.params.collectionId

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
