import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  CollectionCreated,
  CollectionDeleted,
  CollectionFrozen,
  CollectionTokenIdsSet,
  CollectionUnfrozen,
  DropCreated,
  DropDeleted,
  DropModified
} from "../generated/CollectionCreator/CollectionCreator"

export function createCollectionCreatedEvent(
  uri: string,
  owner: Address,
  collectionId: BigInt,
  postId: BigInt,
  amount: BigInt
): CollectionCreated {
  let collectionCreatedEvent = changetype<CollectionCreated>(newMockEvent())

  collectionCreatedEvent.parameters = new Array()

  collectionCreatedEvent.parameters.push(
    new ethereum.EventParam("uri", ethereum.Value.fromString(uri))
  )
  collectionCreatedEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  collectionCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "collectionId",
      ethereum.Value.fromUnsignedBigInt(collectionId)
    )
  )
  collectionCreatedEvent.parameters.push(
    new ethereum.EventParam("postId", ethereum.Value.fromUnsignedBigInt(postId))
  )
  collectionCreatedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return collectionCreatedEvent
}

export function createCollectionDeletedEvent(
  collectionId: BigInt
): CollectionDeleted {
  let collectionDeletedEvent = changetype<CollectionDeleted>(newMockEvent())

  collectionDeletedEvent.parameters = new Array()

  collectionDeletedEvent.parameters.push(
    new ethereum.EventParam(
      "collectionId",
      ethereum.Value.fromUnsignedBigInt(collectionId)
    )
  )

  return collectionDeletedEvent
}

export function createCollectionFrozenEvent(
  collectionId: BigInt
): CollectionFrozen {
  let collectionFrozenEvent = changetype<CollectionFrozen>(newMockEvent())

  collectionFrozenEvent.parameters = new Array()

  collectionFrozenEvent.parameters.push(
    new ethereum.EventParam(
      "collectionId",
      ethereum.Value.fromUnsignedBigInt(collectionId)
    )
  )

  return collectionFrozenEvent
}

export function createCollectionTokenIdsSetEvent(
  tokenIds: Array<BigInt>,
  collectionId: BigInt
): CollectionTokenIdsSet {
  let collectionTokenIdsSetEvent =
    changetype<CollectionTokenIdsSet>(newMockEvent())

  collectionTokenIdsSetEvent.parameters = new Array()

  collectionTokenIdsSetEvent.parameters.push(
    new ethereum.EventParam(
      "tokenIds",
      ethereum.Value.fromUnsignedBigIntArray(tokenIds)
    )
  )
  collectionTokenIdsSetEvent.parameters.push(
    new ethereum.EventParam(
      "collectionId",
      ethereum.Value.fromUnsignedBigInt(collectionId)
    )
  )

  return collectionTokenIdsSetEvent
}

export function createCollectionUnfrozenEvent(
  collectionId: BigInt
): CollectionUnfrozen {
  let collectionUnfrozenEvent = changetype<CollectionUnfrozen>(newMockEvent())

  collectionUnfrozenEvent.parameters = new Array()

  collectionUnfrozenEvent.parameters.push(
    new ethereum.EventParam(
      "collectionId",
      ethereum.Value.fromUnsignedBigInt(collectionId)
    )
  )

  return collectionUnfrozenEvent
}

export function createDropCreatedEvent(
  uri: string,
  designer: Address,
  dropId: BigInt
): DropCreated {
  let dropCreatedEvent = changetype<DropCreated>(newMockEvent())

  dropCreatedEvent.parameters = new Array()

  dropCreatedEvent.parameters.push(
    new ethereum.EventParam("uri", ethereum.Value.fromString(uri))
  )
  dropCreatedEvent.parameters.push(
    new ethereum.EventParam("designer", ethereum.Value.fromAddress(designer))
  )
  dropCreatedEvent.parameters.push(
    new ethereum.EventParam("dropId", ethereum.Value.fromUnsignedBigInt(dropId))
  )

  return dropCreatedEvent
}

export function createDropDeletedEvent(dropId: BigInt): DropDeleted {
  let dropDeletedEvent = changetype<DropDeleted>(newMockEvent())

  dropDeletedEvent.parameters = new Array()

  dropDeletedEvent.parameters.push(
    new ethereum.EventParam("dropId", ethereum.Value.fromUnsignedBigInt(dropId))
  )

  return dropDeletedEvent
}

export function createDropModifiedEvent(dropId: BigInt): DropModified {
  let dropModifiedEvent = changetype<DropModified>(newMockEvent())

  dropModifiedEvent.parameters = new Array()

  dropModifiedEvent.parameters.push(
    new ethereum.EventParam("dropId", ethereum.Value.fromUnsignedBigInt(dropId))
  )

  return dropModifiedEvent
}
