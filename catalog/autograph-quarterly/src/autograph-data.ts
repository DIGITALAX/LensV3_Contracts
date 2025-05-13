import {
  Address,
  BigInt,
  ByteArray,
  Bytes,
  store,
} from "@graphprotocol/graph-ts";
import {
  AutographData,
  CurrencyAdded as CurrencyAddedEvent,
  CurrencyRemoved as CurrencyRemovedEvent,
  DesignerSplitSet as DesignerSplitSetEvent,
  FulfillerBaseSet as FulfillerBaseSetEvent,
  FulfillerSplitSet as FulfillerSplitSetEvent,
  OracleUpdated as OracleUpdatedEvent,
} from "../generated/AutographData/AutographData";
import {
  CurrencyAdded,
  CurrencyRemoved,
  DesignerSplitSet,
  FulfillerBaseSet,
  FulfillerSplitSet,
  OracleUpdated,
} from "../generated/schema";

export function handleCurrencyAdded(event: CurrencyAddedEvent): void {
  let entity = new CurrencyAdded(
    Bytes.fromByteArray(
      ByteArray.fromHexString(event.params.currency.toHexString())
    )
  );
  let data = AutographData.bind(event.address);

  entity.currency = event.params.currency;
  entity.wei = data.getCurrencyWei(event.params.currency);
  entity.rate = data.getCurrencyRate(event.params.currency);

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleCurrencyRemoved(event: CurrencyRemovedEvent): void {
  let entity = new CurrencyRemoved(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.currency = event.params.currency;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  store.remove(
    "CurrencyAdded",
    Bytes.fromByteArray(
      ByteArray.fromHexString(event.params.currency.toHexString())
    ).toHexString()
  );
}

export function handleDesignerSplitSet(event: DesignerSplitSetEvent): void {
  let entity = new DesignerSplitSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.designer = event.params.designer;
  entity.printType = event.params.printType;
  entity.split = event.params.split;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleFulfillerBaseSet(event: FulfillerBaseSetEvent): void {
  let entity = new FulfillerBaseSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.fulfiller = event.params.fulfiller;
  entity.printType = event.params.printType;
  entity.split = event.params.split;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleFulfillerSplitSet(event: FulfillerSplitSetEvent): void {
  let entity = new FulfillerSplitSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.fulfiller = event.params.fulfiller;
  entity.printType = event.params.printType;
  entity.split = event.params.split;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleOracleUpdated(event: OracleUpdatedEvent): void {
  let entity = new OracleUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.currency = event.params.currency;
  entity.rate = event.params.rate;

  let currency = CurrencyAdded.load(
    Bytes.fromByteArray(
      ByteArray.fromHexString(event.params.currency.toHexString())
    )
  );

  if (currency) {
    let data = AutographData.bind(event.address);
    currency.wei = data.getCurrencyWei(event.params.currency);
    currency.rate = event.params.rate;
    currency.save();
  }

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}
