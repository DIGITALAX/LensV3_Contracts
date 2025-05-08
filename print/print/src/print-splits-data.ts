import { BigInt, ByteArray, Bytes, store } from "@graphprotocol/graph-ts";
import {
  CurrencyAdded as CurrencyAddedEvent,
  CurrencyRemoved as CurrencyRemovedEvent,
  SplitsSet as SplitsSetEvent,
} from "../generated/PrintSplitsData/PrintSplitsData";
import { CurrencyAdded, CurrencyRemoved, SplitsSet } from "../generated/schema";

export function handleCurrencyAdded(event: CurrencyAddedEvent): void {
  let entity = new CurrencyAdded(
    Bytes.fromByteArray(
      ByteArray.fromHexString(event.params.currency.toHexString())
    )
  );
  entity.currency = event.params.currency;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.wei = event.params.weiAmount;
  entity.rate = event.params.rate;

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

  let currency = CurrencyAdded.load(
    Bytes.fromByteArray(
      ByteArray.fromHexString(event.params.currency.toHexString())
    )
  );

  if (currency) {
    store.remove(
      "CurrencyAdded",
      Bytes.fromByteArray(
        ByteArray.fromHexString(event.params.currency.toHexString())
      ).toHexString()
    );
  }

  entity.save();
}

export function handleSplitsSet(event: SplitsSetEvent): void {
  let entity = new SplitsSet(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );

  let currencyAdded = new CurrencyAdded(
    Bytes.fromByteArray(
      ByteArray.fromHexString(event.params.currency.toHexString())
    )
  );

  if (currencyAdded) {
    currencyAdded.fulfillerSplit = event.params.fulfillerSplit;
    currencyAdded.fulfillerBase = event.params.fulfillerBase;
    currencyAdded.printType = BigInt.fromI32(event.params.printType);

    currencyAdded.save();
  }

  entity.blockNumber = event.block.number;
  entity.currency = event.params.currency;
  entity.fulfillerSplit = event.params.fulfillerSplit;
  entity.fulfillerBase = event.params.fulfillerBase;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;
  entity.printType = event.params.printType;

  entity.save();
}
