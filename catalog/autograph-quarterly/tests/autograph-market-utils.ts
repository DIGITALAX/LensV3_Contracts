import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt } from "@graphprotocol/graph-ts"
import { OrderCreated } from "../generated/AutographMarket/AutographMarket"

export function createOrderCreatedEvent(
  subOrderIds: Array<BigInt>,
  total: BigInt,
  orderId: BigInt
): OrderCreated {
  let orderCreatedEvent = changetype<OrderCreated>(newMockEvent())

  orderCreatedEvent.parameters = new Array()

  orderCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "subOrderIds",
      ethereum.Value.fromUnsignedBigIntArray(subOrderIds)
    )
  )
  orderCreatedEvent.parameters.push(
    new ethereum.EventParam("total", ethereum.Value.fromUnsignedBigInt(total))
  )
  orderCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "orderId",
      ethereum.Value.fromUnsignedBigInt(orderId)
    )
  )

  return orderCreatedEvent
}
