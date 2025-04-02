import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import {
  CollectionDeleted,
  GalleryCreated,
  GalleryDeleted,
  GalleryEdited,
  GalleryUpdated,
  PostIdConnected
} from "../generated/AutographCollections/AutographCollections"

export function createCollectionDeletedEvent(
  collectionId: BigInt,
  galleryId: BigInt
): CollectionDeleted {
  let collectionDeletedEvent = changetype<CollectionDeleted>(newMockEvent())

  collectionDeletedEvent.parameters = new Array()

  collectionDeletedEvent.parameters.push(
    new ethereum.EventParam(
      "collectionId",
      ethereum.Value.fromUnsignedBigInt(collectionId)
    )
  )
  collectionDeletedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryId",
      ethereum.Value.fromUnsignedBigInt(galleryId)
    )
  )

  return collectionDeletedEvent
}

export function createGalleryCreatedEvent(
  designer: Address,
  galleryId: BigInt
): GalleryCreated {
  let galleryCreatedEvent = changetype<GalleryCreated>(newMockEvent())

  galleryCreatedEvent.parameters = new Array()

  galleryCreatedEvent.parameters.push(
    new ethereum.EventParam("designer", ethereum.Value.fromAddress(designer))
  )
  galleryCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryId",
      ethereum.Value.fromUnsignedBigInt(galleryId)
    )
  )

  return galleryCreatedEvent
}

export function createGalleryDeletedEvent(
  designer: Address,
  galleryId: BigInt
): GalleryDeleted {
  let galleryDeletedEvent = changetype<GalleryDeleted>(newMockEvent())

  galleryDeletedEvent.parameters = new Array()

  galleryDeletedEvent.parameters.push(
    new ethereum.EventParam("designer", ethereum.Value.fromAddress(designer))
  )
  galleryDeletedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryId",
      ethereum.Value.fromUnsignedBigInt(galleryId)
    )
  )

  return galleryDeletedEvent
}

export function createGalleryEditedEvent(
  uri: string,
  galleryId: BigInt
): GalleryEdited {
  let galleryEditedEvent = changetype<GalleryEdited>(newMockEvent())

  galleryEditedEvent.parameters = new Array()

  galleryEditedEvent.parameters.push(
    new ethereum.EventParam("uri", ethereum.Value.fromString(uri))
  )
  galleryEditedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryId",
      ethereum.Value.fromUnsignedBigInt(galleryId)
    )
  )

  return galleryEditedEvent
}

export function createGalleryUpdatedEvent(
  designer: Address,
  galleryId: BigInt
): GalleryUpdated {
  let galleryUpdatedEvent = changetype<GalleryUpdated>(newMockEvent())

  galleryUpdatedEvent.parameters = new Array()

  galleryUpdatedEvent.parameters.push(
    new ethereum.EventParam("designer", ethereum.Value.fromAddress(designer))
  )
  galleryUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "galleryId",
      ethereum.Value.fromUnsignedBigInt(galleryId)
    )
  )

  return galleryUpdatedEvent
}

export function createPostIdConnectedEvent(
  postId: BigInt,
  collectionId: BigInt
): PostIdConnected {
  let postIdConnectedEvent = changetype<PostIdConnected>(newMockEvent())

  postIdConnectedEvent.parameters = new Array()

  postIdConnectedEvent.parameters.push(
    new ethereum.EventParam("postId", ethereum.Value.fromUnsignedBigInt(postId))
  )
  postIdConnectedEvent.parameters.push(
    new ethereum.EventParam(
      "collectionId",
      ethereum.Value.fromUnsignedBigInt(collectionId)
    )
  )

  return postIdConnectedEvent
}
