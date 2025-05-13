import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as"
import { BigInt } from "@graphprotocol/graph-ts"
import { OrderCreated } from "../generated/schema"
import { OrderCreated as OrderCreatedEvent } from "../generated/AutographMarket/AutographMarket"
import { handleOrderCreated } from "../src/autograph-market"
import { createOrderCreatedEvent } from "./autograph-market-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let subOrderIds = [BigInt.fromI32(234)]
    let total = BigInt.fromI32(234)
    let orderId = BigInt.fromI32(234)
    let newOrderCreatedEvent = createOrderCreatedEvent(
      subOrderIds,
      total,
      orderId
    )
    handleOrderCreated(newOrderCreatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("OrderCreated created and stored", () => {
    assert.entityCount("OrderCreated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "OrderCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "subOrderIds",
      "[234]"
    )
    assert.fieldEquals(
      "OrderCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "total",
      "234"
    )
    assert.fieldEquals(
      "OrderCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "orderId",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
