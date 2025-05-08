import { BigInt, ByteArray, Bytes, store } from "@graphprotocol/graph-ts";
import {
  AutographCollections,
  CollectionDeleted as CollectionDeletedEvent,
  GalleryCreated as GalleryCreatedEvent,
  GalleryDeleted as GalleryDeletedEvent,
  GalleryEdited as GalleryEditedEvent,
  GalleryUpdated as GalleryUpdatedEvent,
  PostIdConnected as PostIdConnectedEvent,
} from "../generated/AutographCollections/AutographCollections";
import {
  AgentCollections,
  Collection,
  CollectionDeleted,
  GalleryCreated,
  GalleryDeleted,
  GalleryEdited,
  GalleryUpdated,
  PostIdConnected,
} from "../generated/schema";
import {
  GalleryMetadata as GalleryMetadataTemplate,
  CollectionMetadata as CollectionMetadataTemplate,
} from "../generated/templates";

export function handleCollectionDeleted(event: CollectionDeletedEvent): void {
  let entity = new CollectionDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.collectionId = event.params.collectionId;
  entity.galleryId = event.params.galleryId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  store.remove(
    "Collection",
    Bytes.fromByteArray(
      ByteArray.fromBigInt(event.params.collectionId)
    ).toHexString()
  );

  entity.save();
}

export function handleGalleryCreated(event: GalleryCreatedEvent): void {
  let entity = new GalleryCreated(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.galleryId))
  );
  entity.designer = event.params.designer;
  entity.galleryId = event.params.galleryId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let collection = AutographCollections.bind(event.address);

  entity.uri = collection.getGalleryURI(entity.galleryId);
  let ipfsHash = entity.uri.split("/").pop();
  if (ipfsHash != null) {
    entity.metadata = ipfsHash;
    GalleryMetadataTemplate.create(ipfsHash);
  }

  entity.collectionIds = collection.getGalleryCollectionIds(entity.galleryId);

  let collections: Bytes[] = [];

  for (let i = 0; i < (entity.collectionIds as BigInt[]).length; i++) {
    let coll = new Collection(
      Bytes.fromByteArray(ByteArray.fromBigInt((entity.collectionIds as BigInt[])[i]))
    );
coll.collectionId = (entity.collectionIds as BigInt[])[i];
    coll.acceptedTokens = collection
      .getCollectionAcceptedTokens((entity.collectionIds as BigInt[])[i])
      .map<Bytes>((target: Bytes) => target);
    coll.amount = collection.getCollectionAmount((entity.collectionIds as BigInt[])[i]);
    coll.designer = collection.getCollectionDesigner((entity.collectionIds as BigInt[])[i]);
    coll.galleryId = entity.galleryId;
    coll.npcs = collection.getCollectionNPCs((entity.collectionIds as BigInt[])[i]) .map<Bytes>((target: Bytes) => target);
    coll.uri = collection.getCollectionURI((entity.collectionIds as BigInt[])[i]);
    let ipfsHash = coll.uri.split("/").pop();
    if (ipfsHash != null) {
      coll.metadata = ipfsHash;
      CollectionMetadataTemplate.create(ipfsHash);
    }

    coll.price = collection.getCollectionPrice((entity.collectionIds as BigInt[])[i]);
    coll.type = BigInt.fromI32(
      collection.getCollectionType((entity.collectionIds as BigInt[])[i])
    );

    coll.save();

    collections.push(
      Bytes.fromByteArray(ByteArray.fromBigInt((entity.collectionIds as BigInt[])[i]))
    );

    for (let j = 0; j < (coll.npcs as Bytes[]).length; j++) {
      let npc = AgentCollections.load(
        Bytes.fromByteArray((coll.npcs as Bytes[])[j])
      );

      if (!npc) {
        npc = new AgentCollections(
          Bytes.fromByteArray((coll.npcs as Bytes[])[j])
        );
        npc.npc = (coll.npcs as Bytes[])[j];
      }

      let colls = npc.collections;

      if (!colls) {
        colls = [];
      }
      colls.push(
        Bytes.fromByteArray(ByteArray.fromBigInt((entity.collectionIds as BigInt[])[i]))
      );
      npc.collections = colls;
      npc.save();
    }
  }

  entity.collections = collections;

  entity.save();
}

export function handleGalleryDeleted(event: GalleryDeletedEvent): void {
  let entity = new GalleryDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.designer = event.params.designer;
  entity.galleryId = event.params.galleryId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let gallery = GalleryCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.galleryId))
  );

  if (gallery) {
    for (let i = 0; i < (gallery.collectionIds as BigInt[]).length; i++) {
      store.remove(
        "Collection",
        Bytes.fromByteArray(
          ByteArray.fromBigInt((gallery.collectionIds as BigInt[])[i])
        ).toHexString()
      );
    }
  }

  store.remove(
    "GalleryCreated",
    Bytes.fromByteArray(
      ByteArray.fromBigInt(event.params.galleryId)
    ).toHexString()
  );

  entity.save();
}

export function handleGalleryEdited(event: GalleryEditedEvent): void {
  let entity = new GalleryEdited(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.uri = event.params.uri;
  entity.galleryId = event.params.galleryId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let gallery = GalleryCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.galleryId))
  );

  if (gallery) {
    gallery.uri = event.params.uri;
    let ipfsHash = gallery.uri.split("/").pop();
    if (ipfsHash != null) {
      gallery.metadata = ipfsHash;
      GalleryMetadataTemplate.create(ipfsHash);
    }

    gallery.save();
  }

  entity.save();
}

export function handleGalleryUpdated(event: GalleryUpdatedEvent): void {
  let entity = new GalleryUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.designer = event.params.designer;
  entity.galleryId = event.params.galleryId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let gallery = GalleryCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.galleryId))
  );

  if (gallery) {
    let collection = AutographCollections.bind(event.address);

    gallery.collectionIds = collection.getGalleryCollectionIds(
      entity.galleryId
    );

    let collections = gallery.collections;

    if (!collections) {
      collections = [];
    }

    for (let i = 0; i < (gallery.collectionIds as BigInt[]).length; i++) {
      let coll = Collection.load(
        Bytes.fromByteArray(
          ByteArray.fromBigInt((gallery.collectionIds as BigInt[])[i] as BigInt)
        )
      );

      if (!coll) {
        coll = new Collection(
          Bytes.fromByteArray(
            ByteArray.fromBigInt(
              (gallery.collectionIds as BigInt[])[i] as BigInt
            )
          )
        );
        coll.collectionId = (gallery.collectionIds as BigInt[])[i];
        coll.acceptedTokens = collection
          .getCollectionAcceptedTokens(
            (gallery.collectionIds as BigInt[])[i] as BigInt
          )
          .map<Bytes>((target: Bytes) => target);
        coll.amount = collection.getCollectionAmount(
          (gallery.collectionIds as BigInt[])[i] as BigInt
        );
        coll.designer = collection.getCollectionDesigner(
          (gallery.collectionIds as BigInt[])[i] as BigInt
        );
        coll.galleryId = entity.galleryId;
        coll.npcs = collection
          .getCollectionNPCs((gallery.collectionIds as BigInt[])[i] as BigInt)
          .map<Bytes>((target: Bytes) => target);
        coll.uri = collection.getCollectionURI(
          (gallery.collectionIds as BigInt[])[i] as BigInt
        );
        let ipfsHash = coll.uri.split("/").pop();
        if (ipfsHash != null) {
          coll.metadata = ipfsHash;
          CollectionMetadataTemplate.create(ipfsHash);
        }

        coll.price = collection.getCollectionPrice(
          (gallery.collectionIds as BigInt[])[i] as BigInt
        );
        coll.type = BigInt.fromI32(
          collection.getCollectionType(
            (gallery.collectionIds as BigInt[])[i] as BigInt
          )
        );

        coll.save();

        for (let j = 0; j <(coll.npcs as Bytes[]).length; j++) {
          let npc = AgentCollections.load(
            Bytes.fromByteArray((coll.npcs as Bytes[])[j])
          );

          if (!npc) {
            npc = new AgentCollections(
              Bytes.fromByteArray((coll.npcs as Bytes[])[j])
            );
            npc.npc = (coll.npcs as Bytes[])[j];
          }

          let colls = npc.collections;

          if (!colls) {
            colls = [];
          }
          colls.push(
            Bytes.fromByteArray(
              ByteArray.fromBigInt(
                (gallery.collectionIds as BigInt[])[i] as BigInt
              )
            )
          );
          npc.collections = colls;
          npc.save();
        }
      }

      collections.push(coll.id);
    }

    gallery.collections = collections;
    gallery.save();
  }

  entity.save();
}

export function handlePostIdConnected(event: PostIdConnectedEvent): void {
  let entity = new PostIdConnected(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.postId = event.params.postId;
  entity.collectionId = event.params.collectionId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let collection = AutographCollections.bind(event.address);

  let coll = Collection.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(entity.collectionId))
  );

  if (coll) {
    coll.postIds = collection.getCollectionPostIds(entity.collectionId);

    coll.save();
  }

  entity.save();
}
