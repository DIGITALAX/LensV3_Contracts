import { Bytes, ByteArray, Address } from "@graphprotocol/graph-ts";
import {
  AgentAUUpdated as AgentAUUpdatedEvent,
  AgentPaidAU as AgentPaidAUEvent,
  Spectated as SpectatedEvent,
  SpectatorBalanceUpdated as SpectatorBalanceUpdatedEvent,
  SpectatorRewards,
} from "../generated/SpectatorRewards/SpectatorRewards";
import {
  AgentAUUpdated,
  AgentPaidAU,
  AgentScores,
  Score,
  Spectated,
  SpectatorBalanceUpdated,
  SpectatorInfo,
} from "../generated/schema";
import { SpectateMetadata as SpectateMetadatataTemplate } from "../generated/templates";

export function handleAgentAUUpdated(event: AgentAUUpdatedEvent): void {
  let entity = new AgentAUUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.agent = event.params.agent;
  entity.au = event.params.au;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleAgentPaidAU(event: AgentPaidAUEvent): void {
  let entity = new AgentPaidAU(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.agent = event.params.agent;
  entity.amount = event.params.amount;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let rewards = SpectatorRewards.bind(event.address);

  let spectators = rewards.getAgentCycleSpectators(event.params.agent);

  for (let i = 0; i < (spectators as Address[]).length; i++) {
    let spectator = SpectatorInfo.load(
      (spectators.map<Bytes>((target: Bytes) => target) as Bytes[])[i]
    );
    if (spectator) {
      spectator.auEarned = rewards.getSpectatorAUEarned(
        (spectators as Address[])[i]
      );
      spectator.auClaimed = rewards.getSpectatorAUClaimed(
        (spectators as Address[])[i]
      );
      spectator.auToClaim = rewards.getSpectatorAUToClaim(
        (spectators as Address[])[i]
      );

      spectator.save();
    }
  }
}

export function handleSpectated(event: SpectatedEvent): void {
  let entity = new Spectated(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.count))
  );
  entity.data = event.params.data;
  entity.spectator = event.params.spectator;
  entity.count = event.params.count;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let ipfsHash = entity.data.split("/").pop();
  if (ipfsHash != null) {
    entity.metadata = ipfsHash;
    SpectateMetadatataTemplate.create(ipfsHash);
  }

  let rewards = SpectatorRewards.bind(event.address);

  entity.agent = rewards.getSpectatorAgent(
    entity.spectator as Address,
    entity.count
  );

  entity.save();

  let spectator = SpectatorInfo.load(event.params.spectator);

  if (!spectator) {
    spectator = new SpectatorInfo(event.params.spectator);
    spectator.spectator = event.params.spectator;
    spectator.initialization = rewards.getSpectatorInitialization(
      entity.spectator as Address
    );

    spectator.save();
  }

  let agent = AgentScores.load(entity.agent);

  if (!agent) {
    agent = new AgentScores(entity.agent);
    agent.npc = entity.agent;
  }

  agent.auEarnedTotal = rewards.getAgentAUTotal(entity.agent as Address);
  agent.auEarnedCurrent = rewards.getAgentAUCurrent(entity.agent as Address);

  let scores = agent.scores;

  if (!scores) {
    scores = [];
  }

  let spectatorIdHex = event.params.spectator.toHexString();
  let countHex = entity.count.toHexString();

  let combinedHex = spectatorIdHex + countHex;
  if (combinedHex.length % 2 !== 0) {
    combinedHex = "0" + combinedHex;
  }

  let score = new Score(Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex)));

  score.npc = entity.agent;
  score.scorer = event.params.spectator;
  score.metadata = entity.metadata;
  score.blockTimestamp = entity.blockTimestamp;
  score.blockNumber = entity.blockNumber;
  score.transactionHash = entity.transactionHash;
  score.save();

  scores.push(score.id);

  agent.scores = scores;

  agent.save();
}

export function handleSpectatorBalanceUpdated(
  event: SpectatorBalanceUpdatedEvent
): void {
  let entity = new SpectatorBalanceUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.spectator = event.params.spectator;
  entity.balance = event.params.balance;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let spectator = SpectatorInfo.load(event.params.spectator);
  let rewards = SpectatorRewards.bind(event.address);

  if (spectator) {
    spectator.auEarned = rewards.getSpectatorAUEarned(
      event.params.spectator as Address
    );
    spectator.auClaimed = rewards.getSpectatorAUClaimed(
      event.params.spectator as Address
    );
    spectator.auToClaim = rewards.getSpectatorAUToClaim(
      event.params.spectator as Address
    );

    spectator.save();
  }
}
