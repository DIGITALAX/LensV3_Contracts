import {
  Bytes,
  JSONValueKind,
  dataSource,
  json,
} from "@graphprotocol/graph-ts";
import { CollectionMetadata, GalleryMetadata, SpectateMetadata } from "../generated/schema";

export function handleCollectionMetadata(content: Bytes): void {
  let metadata = new CollectionMetadata(dataSource.stringParam());
  const value = json.fromString(content.toString()).toObject();
  if (value) {
    let description = value.get("description");
    if (description && description.kind === JSONValueKind.STRING) {
      metadata.description = description.toString().substring(0, 2000);
    }
    let title = value.get("title");
    if (title && title.kind === JSONValueKind.STRING) {
      metadata.title = title.toString();
    }
    let tags = value.get("tags");
    if (tags && tags.kind === JSONValueKind.STRING) {
      metadata.tags = tags.toString();
    }

    let images = value.get("images");
    if (images && images.kind === JSONValueKind.ARRAY) {
      metadata.images = images
        .toArray()
        .filter((item) => item.kind === JSONValueKind.STRING)
        .map<string>((item) => item.toString());
    }


    metadata.save();
  }
}

export function handleGalleryMetadata(content: Bytes): void {
  let metadata = new GalleryMetadata(dataSource.stringParam());
  const value = json.fromString(content.toString()).toObject();
  if (value) {
    let image = value.get("image");
    if (image && image.kind === JSONValueKind.STRING) {
      metadata.image = image.toString().substring(0, 2000);
    }
    let title = value.get("title");
    if (title && title.kind === JSONValueKind.STRING) {
      metadata.title = title.toString();
    }

    metadata.save();
  }
}


export function handleSpectateMetadatata(content: Bytes): void {
  let metadata = new SpectateMetadata(dataSource.stringParam());
  const value = json.fromString(content.toString()).toObject();
  if (value) {


    let comment = value.get("comment");
    if (comment && comment.kind === JSONValueKind.STRING) {
      metadata.comment = comment.toString().substring(0, 2000);
    }
    let model = value.get("title");
    if (model && model.kind === JSONValueKind.NUMBER) {
      metadata.model = model.toBigInt();
    }
    let scene = value.get("scene");
    if (scene && scene.kind === JSONValueKind.NUMBER) {
      metadata.scene = scene.toBigInt();
    }
    let chatContext = value.get("chatContext");
    if (chatContext && chatContext.kind === JSONValueKind.NUMBER) {
      metadata.chatContext = chatContext.toBigInt();
    }

    let appearance = value.get("appearance");
    if (appearance && appearance.kind === JSONValueKind.NUMBER) {
      metadata.appearance = appearance.toBigInt();
    }
    let personality = value.get("personality");
    if (personality && personality.kind === JSONValueKind.NUMBER) {
      metadata.personality = personality.toBigInt();
    }
  
    let lora = value.get("lora");
    if (lora && lora.kind === JSONValueKind.NUMBER) {
      metadata.lora = lora.toBigInt();
    }
  
    let collections = value.get("collections");
    if (collections && collections.kind === JSONValueKind.NUMBER) {
      metadata.collections = collections.toBigInt();
    }

    let spriteSheet = value.get("spriteSheet");
    if (spriteSheet && spriteSheet.kind === JSONValueKind.NUMBER) {
      metadata.spriteSheet = spriteSheet.toBigInt();
    }
  
    let tokenizer = value.get("tokenizer");
    if (tokenizer && tokenizer.kind === JSONValueKind.NUMBER) {
      metadata.tokenizer = tokenizer.toBigInt();
    }
  
    let global = value.get("global");
    if (global && global.kind === JSONValueKind.NUMBER) {
      metadata.global = global.toBigInt();
    }
 
    metadata.save();
  }
}