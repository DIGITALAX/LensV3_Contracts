import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  CurrencyAdded,
  CurrencyRemoved,
  SplitsSet
} from "../generated/PrintSplitsData/PrintSplitsData"

export function createCurrencyAddedEvent(
  currency: Address,
  weiAmount: BigInt,
  rate: BigInt
): CurrencyAdded {
  let currencyAddedEvent = changetype<CurrencyAdded>(newMockEvent())

  currencyAddedEvent.parameters = new Array()

  currencyAddedEvent.parameters.push(
    new ethereum.EventParam("currency", ethereum.Value.fromAddress(currency))
  )
  currencyAddedEvent.parameters.push(
    new ethereum.EventParam(
      "weiAmount",
      ethereum.Value.fromUnsignedBigInt(weiAmount)
    )
  )
  currencyAddedEvent.parameters.push(
    new ethereum.EventParam("rate", ethereum.Value.fromUnsignedBigInt(rate))
  )

  return currencyAddedEvent
}

export function createCurrencyRemovedEvent(currency: Address): CurrencyRemoved {
  let currencyRemovedEvent = changetype<CurrencyRemoved>(newMockEvent())

  currencyRemovedEvent.parameters = new Array()

  currencyRemovedEvent.parameters.push(
    new ethereum.EventParam("currency", ethereum.Value.fromAddress(currency))
  )

  return currencyRemovedEvent
}

export function createSplitsSetEvent(
  currency: Address,
  fulfillerSplit: BigInt,
  fulfillerBase: BigInt,
  printType: i32
): SplitsSet {
  let splitsSetEvent = changetype<SplitsSet>(newMockEvent())

  splitsSetEvent.parameters = new Array()

  splitsSetEvent.parameters.push(
    new ethereum.EventParam("currency", ethereum.Value.fromAddress(currency))
  )
  splitsSetEvent.parameters.push(
    new ethereum.EventParam(
      "fulfillerSplit",
      ethereum.Value.fromUnsignedBigInt(fulfillerSplit)
    )
  )
  splitsSetEvent.parameters.push(
    new ethereum.EventParam(
      "fulfillerBase",
      ethereum.Value.fromUnsignedBigInt(fulfillerBase)
    )
  )
  splitsSetEvent.parameters.push(
    new ethereum.EventParam(
      "printType",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(printType))
    )
  )

  return splitsSetEvent
}
