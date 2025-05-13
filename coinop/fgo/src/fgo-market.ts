import { Address, BigInt, ByteArray, Bytes } from "@graphprotocol/graph-ts";
import {
  FGOMarket,
  OrderCreated as OrderCreatedEvent,
  OrderIsFulfilled as OrderIsFulfilledEvent,
  UpdateOrderDetails as UpdateOrderDetailsEvent,
  UpdateOrderMessage as UpdateOrderMessageEvent,
  UpdateOrderStatus as UpdateOrderStatusEvent,
} from "../generated/FGOMarket/FGOMarket";
import {
  CompositeMetadata,
  OrderCreated,
  OrderIsFulfilled,
  UpdateOrderDetails,
  UpdateOrderMessage,
  UpdateOrderStatus,
} from "../generated/schema";
import { ParentFGO } from "../generated/ParentFGO/ParentFGO";
import { CompositeMetadata as CompositeMetadataTemplate } from "../generated/templates";
import { CustomCompositeNFT } from "../generated/CustomCompositeNFT/CustomCompositeNFT";

export function handleOrderCreated(event: OrderCreatedEvent): void {
  let entity = new OrderCreated(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.orderId))
  );
  entity.buyer = event.params.buyer;
  entity.parentId = event.params.parentId;
  entity.orderId = event.params.orderId;
  entity.totalPrice = event.params.totalPrice;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let orders = FGOMarket.bind(event.address);
  let composite = CustomCompositeNFT.bind(
    Address.fromString("0x834e380837691071422a96AAb9F7144058aDfD9a")
  );

  entity.currency = orders.getOrderCurrency(entity.orderId);
  entity.details = orders.getOrderDetails(entity.orderId);
  entity.messages = orders.getOrderMessages(entity.orderId);
  entity.status = BigInt.fromI32(orders.getOrderStatus(entity.orderId));
  entity.isFulfilled = orders.getOrderIsFulfilled(entity.orderId);
  entity.tokenId = orders.getOrderTokenId(entity.orderId);
  entity.parentTokenId = orders.getOrderParentTokenId(entity.orderId);

  entity.compositeURI = composite.tokenURI(entity.tokenId);

  let ipfsHash = entity.compositeURI.split("/").pop();
  if (ipfsHash != null) {
    entity.compositeMetadata = ipfsHash;
    CompositeMetadataTemplate.create(ipfsHash);
  }

  entity.save();
}

export function handleOrderIsFulfilled(event: OrderIsFulfilledEvent): void {
  let entity = new OrderIsFulfilled(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.orderId = event.params.orderId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let orderEntity = OrderCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.orderId))
  );

  if (orderEntity) {
    orderEntity.isFulfilled = true;

    orderEntity.save();
  }

  entity.save();
}

export function handleUpdateOrderDetails(event: UpdateOrderDetailsEvent): void {
  let entity = new UpdateOrderDetails(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.orderId = event.params.orderId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let orderEntity = OrderCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.orderId))
  );
  let orders = FGOMarket.bind(event.address);

  if (orderEntity) {
    orderEntity.details = orders.getOrderDetails(entity.orderId);

    orderEntity.save();
  }
}

export function handleUpdateOrderMessage(event: UpdateOrderMessageEvent): void {
  let entity = new UpdateOrderMessage(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.newMessageDetails = event.params.newMessageDetails;
  entity.orderId = event.params.orderId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let orderEntity = OrderCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.orderId))
  );
  let orders = FGOMarket.bind(event.address);

  if (orderEntity) {
    orderEntity.messages = orders.getOrderMessages(entity.orderId);

    orderEntity.save();
  }
}

export function handleUpdateOrderStatus(event: UpdateOrderStatusEvent): void {
  let entity = new UpdateOrderStatus(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.orderId = event.params.orderId;
  entity.newSubOrderStatus = event.params.newSubOrderStatus;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let orderEntity = OrderCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.orderId))
  );
  let orders = FGOMarket.bind(event.address);

  if (orderEntity) {
    orderEntity.status = BigInt.fromI32(orders.getOrderStatus(entity.orderId));

    orderEntity.save();
  }
}
