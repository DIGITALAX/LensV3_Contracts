import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  Approval,
  ApprovalForAll,
  ParentCreated,
  ParentWithChildrenMinted,
  Transfer
} from "../generated/ParentFGO/ParentFGO"

export function createApprovalEvent(
  owner: Address,
  approved: Address,
  tokenId: BigInt
): Approval {
  let approvalEvent = changetype<Approval>(newMockEvent())

  approvalEvent.parameters = new Array()

  approvalEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  approvalEvent.parameters.push(
    new ethereum.EventParam("approved", ethereum.Value.fromAddress(approved))
  )
  approvalEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )

  return approvalEvent
}

export function createApprovalForAllEvent(
  owner: Address,
  operator: Address,
  approved: boolean
): ApprovalForAll {
  let approvalForAllEvent = changetype<ApprovalForAll>(newMockEvent())

  approvalForAllEvent.parameters = new Array()

  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("operator", ethereum.Value.fromAddress(operator))
  )
  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("approved", ethereum.Value.fromBoolean(approved))
  )

  return approvalForAllEvent
}

export function createParentCreatedEvent(parentId: BigInt): ParentCreated {
  let parentCreatedEvent = changetype<ParentCreated>(newMockEvent())

  parentCreatedEvent.parameters = new Array()

  parentCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "parentId",
      ethereum.Value.fromUnsignedBigInt(parentId)
    )
  )

  return parentCreatedEvent
}

export function createParentWithChildrenMintedEvent(
  tokenId: BigInt,
  parentId: BigInt
): ParentWithChildrenMinted {
  let parentWithChildrenMintedEvent =
    changetype<ParentWithChildrenMinted>(newMockEvent())

  parentWithChildrenMintedEvent.parameters = new Array()

  parentWithChildrenMintedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  parentWithChildrenMintedEvent.parameters.push(
    new ethereum.EventParam(
      "parentId",
      ethereum.Value.fromUnsignedBigInt(parentId)
    )
  )

  return parentWithChildrenMintedEvent
}

export function createTransferEvent(
  from: Address,
  to: Address,
  tokenId: BigInt
): Transfer {
  let transferEvent = changetype<Transfer>(newMockEvent())

  transferEvent.parameters = new Array()

  transferEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  transferEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )
  transferEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )

  return transferEvent
}
