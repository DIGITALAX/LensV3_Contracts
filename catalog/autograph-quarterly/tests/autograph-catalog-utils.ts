import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt } from "@graphprotocol/graph-ts"
import {
  AutographCreated,
  AutographTokensMinted
} from "../generated/AutographCatalog/AutographCatalog"

export function createAutographCreatedEvent(
  uri: string,
  amount: BigInt
): AutographCreated {
  let autographCreatedEvent = changetype<AutographCreated>(newMockEvent())

  autographCreatedEvent.parameters = new Array()

  autographCreatedEvent.parameters.push(
    new ethereum.EventParam("uri", ethereum.Value.fromString(uri))
  )
  autographCreatedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return autographCreatedEvent
}

export function createAutographTokensMintedEvent(
  amount: i32
): AutographTokensMinted {
  let autographTokensMintedEvent =
    changetype<AutographTokensMinted>(newMockEvent())

  autographTokensMintedEvent.parameters = new Array()

  autographTokensMintedEvent.parameters.push(
    new ethereum.EventParam(
      "amount",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(amount))
    )
  )

  return autographTokensMintedEvent
}
