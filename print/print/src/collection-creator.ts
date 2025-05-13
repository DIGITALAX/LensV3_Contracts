import { BigInt, ByteArray, Bytes, store } from "@graphprotocol/graph-ts";
import {
  CollectionCreated as CollectionCreatedEvent,
  CollectionCreator,
  CollectionDeleted as CollectionDeletedEvent,
  CollectionFrozen as CollectionFrozenEvent,
  CollectionTokenIdsSet as CollectionTokenIdsSetEvent,
  CollectionUnfrozen as CollectionUnfrozenEvent,
  DropCreated as DropCreatedEvent,
  DropDeleted as DropDeletedEvent,
  DropModified as DropModifiedEvent,
} from "../generated/CollectionCreator/CollectionCreator";
import {
  CollectionCreated,
  CollectionDeleted,
  CollectionFrozen,
  CollectionTokenIdsSet,
  CollectionUnfrozen,
  DropCreated,
  DropDeleted,
  DropModified,
} from "../generated/schema";
import {
  CollectionMetadata as CollectionMetadataTemplate,
  DropMetadata as DropMetadataTemplate,
} from "../generated/templates";

export function handleCollectionCreated(event: CollectionCreatedEvent): void {
  let entity = new CollectionCreated(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.collectionId))
  );
  entity.uri = event.params.uri;
  entity.designer = event.params.owner;
  entity.collectionId = event.params.collectionId;
  entity.postId = event.params.postId;
  entity.amount = event.params.amount;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let creator = CollectionCreator.bind(event.address);

  let ipfsHash = event.params.uri.split("/").pop();
  if (ipfsHash != null) {
    entity.metadata = ipfsHash;
    CollectionMetadataTemplate.create(ipfsHash);
  }

  entity.dropId = creator.getCollectionDropId(entity.collectionId);
  entity.price = creator.getCollectionPrice(entity.collectionId);
  entity.printType = BigInt.fromI32(
    creator.getCollectionPrintType(entity.collectionId)
  );
  entity.fulfiller = creator.getCollectionFulfiller(entity.collectionId);
  entity.origin = BigInt.fromI32(
    creator.getCollectionOrigin(entity.collectionId)
  );
  entity.acceptedTokens = creator
    .getCollectionAcceptedTokens(entity.collectionId)
    .map<Bytes>((target: Bytes) => target);
  entity.unlimited = creator.getCollectionUnlimited(entity.collectionId);
  entity.frozen = false;

  let dropEntity = DropCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(entity.dropId as BigInt))
  );

  if (dropEntity) {
    dropEntity.collections = creator
      .getDropCollectionIds(dropEntity.dropId)
      .map<Bytes>((target) =>
        Bytes.fromByteArray(ByteArray.fromBigInt(target))
      );

    entity.drop = Bytes.fromByteArray(
      ByteArray.fromBigInt(entity.dropId as BigInt)
    );

    dropEntity.save();
  }

  entity.save();
}

export function handleCollectionDeleted(event: CollectionDeletedEvent): void {
  let entity = new CollectionDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.collectionId = event.params.collectionId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityCollection = CollectionCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.collectionId))
  );
  let creator = CollectionCreator.bind(event.address);

  if (entityCollection) {
    if (entityCollection.dropId) {
      let dropEntity = DropCreated.load(
        Bytes.fromByteArray(
          ByteArray.fromBigInt(entityCollection.dropId as BigInt)
        )
      );

      if (dropEntity) {
        dropEntity.collections = creator
          .getDropCollectionIds(dropEntity.dropId)
          .map<Bytes>((target) =>
            Bytes.fromByteArray(ByteArray.fromBigInt(target))
          );

        dropEntity.save();
      }
    }

    store.remove(
      "CollectionCreated",
      Bytes.fromByteArray(
        ByteArray.fromBigInt(event.params.collectionId)
      ).toHexString()
    );
  }
}

export function handleCollectionFrozen(event: CollectionFrozenEvent): void {
  let entity = new CollectionFrozen(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.collectionId = event.params.collectionId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityCollection = CollectionCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.collectionId))
  );

  if (entityCollection) {
    entityCollection.frozen = true;
    entityCollection.save();
  }
}

export function handleCollectionTokenIdsSet(
  event: CollectionTokenIdsSetEvent
): void {
  let entity = new CollectionTokenIdsSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.tokenIds = event.params.tokenIds;
  entity.collectionId = event.params.collectionId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityCollection = CollectionCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.collectionId))
  );
  let creator = CollectionCreator.bind(event.address);

  if (entityCollection) {
    entityCollection.tokenIdsMinted = creator.getCollectionMintedTokenIds(
      entity.collectionId
    );
    entityCollection.save();
  }
}

export function handleCollectionUnfrozen(event: CollectionUnfrozenEvent): void {
  let entity = new CollectionUnfrozen(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.collectionId = event.params.collectionId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityCollection = CollectionCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.collectionId))
  );
  if (entityCollection) {
    entityCollection.frozen = false;
    entityCollection.save();
  }
}

export function handleDropCreated(event: DropCreatedEvent): void {
  let entity = new DropCreated(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.dropId))
  );
  entity.uri = event.params.uri;
  entity.designer = event.params.designer;
  entity.dropId = event.params.dropId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let ipfsHash = event.params.uri.split("/").pop();
  if (ipfsHash != null) {
    entity.metadata = ipfsHash;
    DropMetadataTemplate.create(ipfsHash);
  }

  entity.save();
}

export function handleDropDeleted(event: DropDeletedEvent): void {
  let entity = new DropDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.dropId = event.params.dropId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityDrop = DropCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.dropId))
  );

  if (entityDrop) {
    if (entityDrop.collections) {
      for (let i = 0; i < (entityDrop.collections as Bytes[]).length; i++) {
        let collectionEntity = CollectionCreated.load(
          (entityDrop.collections as Bytes[])[i]
        );

        if (collectionEntity) {
          collectionEntity.dropId = BigInt.fromI32(0);
          collectionEntity.drop = null;

          collectionEntity.save();
        }
      }
    }

    store.remove(
      "DropCreated",
      Bytes.fromByteArray(
        ByteArray.fromBigInt(event.params.dropId)
      ).toHexString()
    );
  }
}

export function handleDropModified(event: DropModifiedEvent): void {
  let entity = new DropModified(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.dropId = event.params.dropId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityDrop = DropCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.dropId))
  );
  let creator = CollectionCreator.bind(event.address);

  if (entityDrop) {
    entityDrop.uri = creator.getDropURI(entityDrop.dropId);

    let ipfsHash = entityDrop.uri.split("/").pop();
    if (ipfsHash != null) {
      entityDrop.metadata = ipfsHash;
      DropMetadataTemplate.create(ipfsHash);
    }

    let currentCollections = entityDrop.collections;
    if (currentCollections) {
      for (let i = 0; i < (currentCollections as Bytes[]).length; i++) {
        let entityCollection = CollectionCreated.load(
          (currentCollections as Bytes[])[i]
        );

        if (entityCollection) {
          entityCollection.dropId = BigInt.fromI32(0);
          entityCollection.drop = null;

          entityCollection.save();
        }
      }
    }

    entityDrop.collections = creator
      .getDropCollectionIds(entityDrop.dropId)
      .map<Bytes>((target) =>
        Bytes.fromByteArray(ByteArray.fromBigInt(target))
      );

    entityDrop.save();

    for (let i = 0; i < (entityDrop.collections as Bytes[]).length; i++) {
      let entityCollection = CollectionCreated.load(
        (entityDrop.collections as Bytes[])[i]
      );

      if (entityCollection) {
        entityCollection.dropId = event.params.dropId;
        entityCollection.drop = Bytes.fromByteArray(
          ByteArray.fromBigInt(event.params.dropId)
        );

        entityCollection.save();
      }
    }
  }
}
