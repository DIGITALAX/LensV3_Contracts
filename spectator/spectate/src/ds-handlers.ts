import {
  Bytes,
  JSONValueKind,
  dataSource,
  json,
} from "@graphprotocol/graph-ts";
import { SpectateMetadata } from "../generated/schema";

export function handleSpectateMetadata(content: Bytes): void {
  let metadata = new SpectateMetadata(dataSource.stringParam());
  const value = json.fromString(content.toString()).toObject();
  if (value) {
    let comment = value.get("comment");
    if (comment && comment.kind === JSONValueKind.STRING) {
      metadata.comment = comment.toString();
    }

    let model = value.get("model");
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

    let collections = value.get("collections");
    if (collections && collections.kind === JSONValueKind.NUMBER) {
      metadata.collections = collections.toBigInt();
    }
    let personality = value.get("personality");
    if (personality && personality.kind === JSONValueKind.NUMBER) {
      metadata.personality = personality.toBigInt();
    }
    let training = value.get("training");
    if (training && training.kind === JSONValueKind.NUMBER) {
      metadata.training = training.toBigInt();
    }
    let tokenizer = value.get("tokenizer");
    if (tokenizer && tokenizer.kind === JSONValueKind.NUMBER) {
      metadata.tokenizer = tokenizer.toBigInt();
    }
    let lora = value.get("lora");
    if (lora && lora.kind === JSONValueKind.NUMBER) {
      metadata.lora = lora.toBigInt();
    }
    let spriteSheet = value.get("spriteSheet");
    if (spriteSheet && spriteSheet.kind === JSONValueKind.NUMBER) {
      metadata.spriteSheet = spriteSheet.toBigInt();
    }
    let global = value.get("global");
    if (global && global.kind === JSONValueKind.NUMBER) {
      metadata.global = global.toBigInt();
    }

    metadata.save();
  }
}
