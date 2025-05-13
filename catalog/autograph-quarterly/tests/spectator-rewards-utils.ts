import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  AgentAUUpdated,
  AgentPaidAU,
  Spectated,
  SpectatorBalanceUpdated,
} from "../generated/SpectatorRewards/SpectatorRewards"

export function createAgentAUUpdatedEvent(
  agent: Address,
  au: BigInt
): AgentAUUpdated {
  let agentAuUpdatedEvent = changetype<AgentAUUpdated>(newMockEvent())

  agentAuUpdatedEvent.parameters = new Array()

  agentAuUpdatedEvent.parameters.push(
    new ethereum.EventParam("agent", ethereum.Value.fromAddress(agent))
  )
  agentAuUpdatedEvent.parameters.push(
    new ethereum.EventParam("au", ethereum.Value.fromUnsignedBigInt(au))
  )

  return agentAuUpdatedEvent
}

export function createAgentPaidAUEvent(
  agent: Address,
  amount: BigInt
): AgentPaidAU {
  let agentPaidAuEvent = changetype<AgentPaidAU>(newMockEvent())

  agentPaidAuEvent.parameters = new Array()

  agentPaidAuEvent.parameters.push(
    new ethereum.EventParam("agent", ethereum.Value.fromAddress(agent))
  )
  agentPaidAuEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return agentPaidAuEvent
}

export function createSpectatedEvent(
  data: string,
  spectator: Address,
  count: BigInt
): Spectated {
  let spectatedEvent = changetype<Spectated>(newMockEvent())

  spectatedEvent.parameters = new Array()

  spectatedEvent.parameters.push(
    new ethereum.EventParam("data", ethereum.Value.fromString(data))
  )
  spectatedEvent.parameters.push(
    new ethereum.EventParam("spectator", ethereum.Value.fromAddress(spectator))
  )
  spectatedEvent.parameters.push(
    new ethereum.EventParam("count", ethereum.Value.fromUnsignedBigInt(count))
  )

  return spectatedEvent
}

export function createSpectatorBalanceUpdatedEvent(
  spectator: Address,
  balance: BigInt
): SpectatorBalanceUpdated {
  let spectatorBalanceUpdatedEvent =
    changetype<SpectatorBalanceUpdated>(newMockEvent())

  spectatorBalanceUpdatedEvent.parameters = new Array()

  spectatorBalanceUpdatedEvent.parameters.push(
    new ethereum.EventParam("spectator", ethereum.Value.fromAddress(spectator))
  )
  spectatorBalanceUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "balance",
      ethereum.Value.fromUnsignedBigInt(balance)
    )
  )

  return spectatorBalanceUpdatedEvent
}

