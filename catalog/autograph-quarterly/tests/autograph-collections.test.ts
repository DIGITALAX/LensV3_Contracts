import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { CollectionDeleted } from "../generated/schema"
import { CollectionDeleted as CollectionDeletedEvent } from "../generated/AutographCollections/AutographCollections"
import { handleCollectionDeleted } from "../src/autograph-collections"
import { createCollectionDeletedEvent } from "./autograph-collections-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let collectionId = BigInt.fromI32(234)
    let galleryId = BigInt.fromI32(234)
    let newCollectionDeletedEvent = createCollectionDeletedEvent(
      collectionId,
      galleryId
    )
    handleCollectionDeleted(newCollectionDeletedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("CollectionDeleted created and stored", () => {
    assert.entityCount("CollectionDeleted", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "CollectionDeleted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "collectionId",
      "234"
    )
    assert.fieldEquals(
      "CollectionDeleted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "galleryId",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
