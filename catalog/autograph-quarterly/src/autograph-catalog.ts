import { BigInt, ByteArray, Bytes } from "@graphprotocol/graph-ts";
import {
  AutographCatalog,
  AutographCreated as AutographCreatedEvent,
  AutographTokensMinted as AutographTokensMintedEvent,
} from "../generated/AutographCatalog/AutographCatalog";
import { AutographCreated, AutographTokensMinted } from "../generated/schema";

export function handleAutographCreated(event: AutographCreatedEvent): void {
  let entity = new AutographCreated(
    Bytes.fromByteArray(ByteArray.fromBigInt(BigInt.fromI32(1)))
  );
  entity.uri = event.params.uri;
  entity.amount = event.params.amount;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let catalog = AutographCatalog.bind(event.address);
  let count = catalog.getAutographPageCount();
  entity.pageCount = BigInt.fromI32(count);
  entity.acceptedTokens = catalog.getAutographAcceptedTokens().map<Bytes>((target: Bytes) => target);
  entity.designer = catalog.getAutographDesigner();
  entity.price = catalog.getAutographPrice();
  entity.postId = catalog.getAutographPostId();
  let pages: string[] = [];

  for (let i = 1; i <= count; i++) {
    pages.push(catalog.getAutographPage(BigInt.fromI32(i)));
  }

  entity.pages = pages;

  entity.save();
}

export function handleAutographTokensMinted(
  event: AutographTokensMintedEvent
): void {
  let entity = new AutographTokensMinted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.amount = event.params.amount;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let auto =  AutographCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(BigInt.fromI32(1)))
  );
  let catalog = AutographCatalog.bind(event.address);

  if (auto) {
    auto.minted = catalog.getAutographMinted();
    auto.save();
  }
  entity.save();
}
