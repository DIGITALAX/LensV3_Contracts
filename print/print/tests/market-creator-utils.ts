import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  OrderCreated,
  OrderIsFulfilled,
  UpdateOrderDetails,
  UpdateOrderMessage,
  UpdateOrderStatus
} from "../generated/MarketCreator/MarketCreator"

export function createOrderCreatedEvent(
  buyer: Address,
  collectionId: BigInt,
  orderId: BigInt,
  totalPrice: BigInt
): OrderCreated {
  let orderCreatedEvent = changetype<OrderCreated>(newMockEvent())

  orderCreatedEvent.parameters = new Array()

  orderCreatedEvent.parameters.push(
    new ethereum.EventParam("buyer", ethereum.Value.fromAddress(buyer))
  )
  orderCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "collectionId",
      ethereum.Value.fromUnsignedBigInt(collectionId)
    )
  )
  orderCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "orderId",
      ethereum.Value.fromUnsignedBigInt(orderId)
    )
  )
  orderCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "totalPrice",
      ethereum.Value.fromUnsignedBigInt(totalPrice)
    )
  )

  return orderCreatedEvent
}

export function createOrderIsFulfilledEvent(orderId: BigInt): OrderIsFulfilled {
  let orderIsFulfilledEvent = changetype<OrderIsFulfilled>(newMockEvent())

  orderIsFulfilledEvent.parameters = new Array()

  orderIsFulfilledEvent.parameters.push(
    new ethereum.EventParam(
      "orderId",
      ethereum.Value.fromUnsignedBigInt(orderId)
    )
  )

  return orderIsFulfilledEvent
}

export function createUpdateOrderDetailsEvent(
  orderId: BigInt
): UpdateOrderDetails {
  let updateOrderDetailsEvent = changetype<UpdateOrderDetails>(newMockEvent())

  updateOrderDetailsEvent.parameters = new Array()

  updateOrderDetailsEvent.parameters.push(
    new ethereum.EventParam(
      "orderId",
      ethereum.Value.fromUnsignedBigInt(orderId)
    )
  )

  return updateOrderDetailsEvent
}

export function createUpdateOrderMessageEvent(
  newMessageDetails: string,
  orderId: BigInt
): UpdateOrderMessage {
  let updateOrderMessageEvent = changetype<UpdateOrderMessage>(newMockEvent())

  updateOrderMessageEvent.parameters = new Array()

  updateOrderMessageEvent.parameters.push(
    new ethereum.EventParam(
      "newMessageDetails",
      ethereum.Value.fromString(newMessageDetails)
    )
  )
  updateOrderMessageEvent.parameters.push(
    new ethereum.EventParam(
      "orderId",
      ethereum.Value.fromUnsignedBigInt(orderId)
    )
  )

  return updateOrderMessageEvent
}

export function createUpdateOrderStatusEvent(
  orderId: BigInt,
  newSubOrderStatus: i32
): UpdateOrderStatus {
  let updateOrderStatusEvent = changetype<UpdateOrderStatus>(newMockEvent())

  updateOrderStatusEvent.parameters = new Array()

  updateOrderStatusEvent.parameters.push(
    new ethereum.EventParam(
      "orderId",
      ethereum.Value.fromUnsignedBigInt(orderId)
    )
  )
  updateOrderStatusEvent.parameters.push(
    new ethereum.EventParam(
      "newSubOrderStatus",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(newSubOrderStatus))
    )
  )

  return updateOrderStatusEvent
}
