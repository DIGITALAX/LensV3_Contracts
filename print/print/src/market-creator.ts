import { BigInt, ByteArray, Bytes } from "@graphprotocol/graph-ts";
import {
  MarketCreator,
  OrderCreated as OrderCreatedEvent,
  OrderIsFulfilled as OrderIsFulfilledEvent,
  UpdateOrderDetails as UpdateOrderDetailsEvent,
  UpdateOrderMessage as UpdateOrderMessageEvent,
  UpdateOrderStatus as UpdateOrderStatusEvent,
} from "../generated/MarketCreator/MarketCreator";
import {
  OrderCreated,
  OrderIsFulfilled,
  UpdateOrderDetails,
  UpdateOrderMessage,
  UpdateOrderStatus,
} from "../generated/schema";

export function handleOrderCreated(event: OrderCreatedEvent): void {
  let entity = new OrderCreated(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.orderId))
  );

  let orders = MarketCreator.bind(event.address);

  entity.buyer = event.params.buyer;
  entity.collectionId = event.params.collectionId;
  entity.orderId = event.params.orderId;
  entity.totalPrice = event.params.totalPrice;
  entity.currency = orders.getOrderCurrency(entity.orderId);
  entity.amount = orders.getOrderAmount(entity.orderId);
  entity.details = orders.getOrderDetails(entity.orderId);
  entity.collection = Bytes.fromByteArray(
    ByteArray.fromBigInt(event.params.collectionId)
  );

  entity.messages = orders.getOrderMessages(entity.orderId);
  entity.status = BigInt.fromI32(orders.getOrderStatus(entity.orderId));  entity.isFulfilled = orders.getOrderIsFulfilled(entity.orderId);
  entity.tokenIds = orders.getOrderTokenIds(entity.orderId);
  entity.fulfiller = orders.getOrderFulfiller(entity.orderId);

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

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

  let orderEntity = OrderCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.orderId))
  );
  let orders = MarketCreator.bind(event.address);

  if (orderEntity) {
    orderEntity.details = orders.getOrderDetails(entity.orderId);

    orderEntity.save();
  }

  entity.save();
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
  let orders = MarketCreator.bind(event.address);

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
  let orders = MarketCreator.bind(event.address);

  if (orderEntity) {
    orderEntity.status = BigInt.fromI32(orders.getOrderStatus(entity.orderId));

    orderEntity.save();
  }
}
