import { Address, BigInt, ByteArray, Bytes } from "@graphprotocol/graph-ts";
import {
  Approval as ApprovalEvent,
  ApprovalForAll as ApprovalForAllEvent,
  ParentCreated as ParentCreatedEvent,
  ParentFGO,
  ParentWithChildrenMinted as ParentWithChildrenMintedEvent,
  Transfer as TransferEvent,
} from "../generated/ParentFGO/ParentFGO";
import {
  Approval,
  ApprovalForAll,
  ChildCreated,
  ParentCreated,
  ParentWithChildrenMinted,
  Transfer,
} from "../generated/schema";
import { ChildFGO } from "../generated/ChildFGO/ChildFGO";

export function handleApproval(event: ApprovalEvent): void {
  let entity = new Approval(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.owner = event.params.owner;
  entity.approved = event.params.approved;
  entity.tokenId = event.params.tokenId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleApprovalForAll(event: ApprovalForAllEvent): void {
  let entity = new ApprovalForAll(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.owner = event.params.owner;
  entity.operator = event.params.operator;
  entity.approved = event.params.approved;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleParentCreated(event: ParentCreatedEvent): void {
  let entity = new ParentCreated(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.parentId))
  );
  entity.parentId = event.params.parentId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let parent = ParentFGO.bind(event.address);
  let child = ChildFGO.bind(
    Address.fromString("0x4b4d0e7DF49066C76c620Df037887b660DeC47B7")
  );

  entity.price = parent.getParentPrice(entity.parentId);
  entity.poster = parent.getParentPoster(entity.parentId);
  entity.uri = parent.getParentURI(entity.parentId);
  entity.printType = BigInt.fromI32(parent.getParentPrintType(entity.parentId));

  entity.childIds = parent.getParentChildIds(entity.parentId);
  let children: Bytes[] = [];

  for (let i = 0; i < (entity.childIds as BigInt[]).length; i++) {
    let entityChild = new ChildCreated(
      Bytes.fromByteArray(
        ByteArray.fromBigInt((entity.childIds as BigInt[])[i])
      )
    );

    entityChild.price = child.getChildPrice((entity.childIds as BigInt[])[i]);
    entityChild.uri = child.getChildURI((entity.childIds as BigInt[])[i]);
    children.push(
      Bytes.fromByteArray(
        ByteArray.fromBigInt((entity.childIds as BigInt[])[i])
      )
    );
    entityChild.save();
  }

  entity.children = children;

  entity.save();
}

export function handleParentWithChildrenMinted(
  event: ParentWithChildrenMintedEvent
): void {
  let entity = new ParentWithChildrenMinted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.tokenId = event.params.tokenId;
  entity.parentId = event.params.parentId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleTransfer(event: TransferEvent): void {
  let entity = new Transfer(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.from = event.params.from;
  entity.to = event.params.to;
  entity.tokenId = event.params.tokenId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}
