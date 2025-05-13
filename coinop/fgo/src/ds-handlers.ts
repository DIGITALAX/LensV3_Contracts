import {
  Bytes,
  JSONValueKind,
  dataSource,
  json,
} from "@graphprotocol/graph-ts";
import { CompositeMetadata } from "../generated/schema";

export function handleCompositeMetadata(content: Bytes): void {
  let metadata = new CompositeMetadata(dataSource.stringParam());
  const value = json.fromString(content.toString()).toObject();
  if (value) {
    let image = value.get("image");
    if (image && image.kind === JSONValueKind.STRING) {
      metadata.image = image.toString();
    }

    let title = value.get("title");
    if (
      title &&
      title.kind === JSONValueKind.STRING &&
      !title.toString().includes("base64")
    ) {
      metadata.title = title.toString();
    }

    let color = value.get("color");
    if (
      color &&
      color.kind === JSONValueKind.STRING &&
      !color.toString().includes("base64")
    ) {
      metadata.color = color.toString();
    }

    let size = value.get("size");
    if (
      size &&
      size.kind === JSONValueKind.STRING &&
      !size.toString().includes("base64")
    ) {
      metadata.size = size.toString();
    }

    metadata.save();
  }
}
