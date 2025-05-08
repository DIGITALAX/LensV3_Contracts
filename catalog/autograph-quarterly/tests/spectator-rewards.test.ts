import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { AgentAUUpdated } from "../generated/schema"
import { AgentAUUpdated as AgentAUUpdatedEvent } from "../generated/SpectatorRewards/SpectatorRewards"
import { handleAgentAUUpdated } from "../src/spectator-rewards"
import { createAgentAUUpdatedEvent } from "./spectator-rewards-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let agent = Address.fromString("0x0000000000000000000000000000000000000001")
    let au = BigInt.fromI32(234)
    let newAgentAUUpdatedEvent = createAgentAUUpdatedEvent(agent, au)
    handleAgentAUUpdated(newAgentAUUpdatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("AgentAUUpdated created and stored", () => {
    assert.entityCount("AgentAUUpdated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "AgentAUUpdated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "agent",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "AgentAUUpdated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "au",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
