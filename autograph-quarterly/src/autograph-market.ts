import { BigInt, ByteArray, Bytes } from "@graphprotocol/graph-ts";
import {
  AutographMarket,
  OrderCreated as OrderCreatedEvent,
} from "../generated/AutographMarket/AutographMarket";
import {
  AgentCollections,
  Collection,
  OrderCreated,
  SubOrder,
} from "../generated/schema";

export function handleOrderCreated(event: OrderCreatedEvent): void {
  let entity = new OrderCreated(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.orderId))
  );
  entity.subOrderIds = event.params.subOrderIds;
  entity.total = event.params.total;
  entity.orderId = event.params.orderId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let market = AutographMarket.bind(event.address);

  entity.fulfillment = market.getOrderFulfillment(entity.orderId);

  let subOrders: Bytes[] = [];

  for (let i = 0; i < entity.subOrderIds.length; i++) {
    let subOrder = new SubOrder(
      Bytes.fromByteArray(ByteArray.fromBigInt(entity.subOrderIds[i]))
    );

    subOrder.amount = market.getSubOrderAmount(entity.subOrderIds[i]);
    subOrder.autographType = BigInt.fromI32(
      market.getSubOrderType(entity.subOrderIds[i])
    );
    subOrder.collectionId = market.getSubOrderCollectionId(
      entity.subOrderIds[i]
    );
    subOrder.currency = market.getSubOrderCurrency(entity.subOrderIds[i]);
    subOrder.designer = market.getSubOrderDesigner(entity.subOrderIds[i]);
    subOrder.fulfiller = market.getSubOrderFulfiller(entity.subOrderIds[i]);
    subOrder.designerAmount = market.getSubOrderDesignerAmount(
      entity.subOrderIds[i]
    );
    subOrder.fulfillerAmount = market.getSubOrderFulfillerAmount(
      entity.subOrderIds[i]
    );
    subOrder.total = market.getSubOrderTotal(entity.subOrderIds[i]);
    subOrder.mintedTokenIds = market.getSubOrderTokensMinted(
      entity.subOrderIds[i]
    );

    subOrder.save();

    subOrders.push(
      Bytes.fromByteArray(ByteArray.fromBigInt(entity.subOrderIds[i]))
    );

    let coll = Collection.load(
      Bytes.fromByteArray(ByteArray.fromBigInt(subOrder.collectionId))
    );

    if (coll) {
      let tokens = coll.mintedTokenIds;

      if (!tokens) {
        tokens = [];
      }

      for (let j = 0; j < tokens.length; j++) {
        tokens.push(tokens[j]);
      }

      coll.mintedTokenIds = tokens;

      coll.save();

      if (BigInt.fromI32(tokens.length) == coll.amount) {
        for (let j = 0; j < (coll.npcs as Bytes[]).length; j++) {
          let npcCol = AgentCollections.load(
            Bytes.fromByteArray((coll.npcs as Bytes[])[j])
          );

          if (npcCol) {
            let newCols: Bytes[] = [];

            for (let k = 0; i < (npcCol.collections as Bytes[]).length; k++) {
              if (
                (npcCol.collections as Bytes[])[k] !==
                Bytes.fromByteArray(ByteArray.fromBigInt(subOrder.collectionId))
              ) {
                newCols.push((npcCol.collections as Bytes[])[k]);
              }
            }

            npcCol.collections = newCols;

            npcCol.save();
          }
        }
      }
    }
  }

  entity.subOrders = subOrders;

  entity.save();
}
