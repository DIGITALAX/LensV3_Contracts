import {
  Address,
  BigInt,
  ByteArray,
  Bytes,
  log,
} from "@graphprotocol/graph-ts";
import {
  AgentAUUpdated as AgentAUUpdatedEvent,
  AgentPaidAU as AgentPaidAUEvent,
  Spectated as SpectatedEvent,
  SpectatorBalanceUpdated as SpectatorBalanceUpdatedEvent,
  SpectatorRewards,
} from "../generated/SpectatorRewards/SpectatorRewards";
import {
  Activity,
  Agent,
  AgentAUUpdated,
  AgentPaidAU,
  Spectated,
  Spectator,
  SpectatorBalanceUpdated,
} from "../generated/schema";
import { SpectateMetadata as SpectateMetadataTemplate } from "../generated/templates";

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

  let agent = Agent.load(
    Bytes.fromByteArray(
      ByteArray.fromHexString(event.params.agent.toHexString())
    )
  );
  let rewards = SpectatorRewards.bind(event.address);

  if (agent) {
    agent.au = rewards.getAgentAUCurrent(agent.address as Address);
    agent.auTotal = rewards.getAgentAUTotal(agent.address as Address);
    agent.cycleSpectators = [];
    agent.save();
  }
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

  let agent = Agent.load(
    Bytes.fromByteArray(
      ByteArray.fromHexString(event.params.agent.toHexString())
    )
  );
  let rewards = SpectatorRewards.bind(event.address);

  if (agent) {
    let cycle = agent.cycleSpectators;

    if (!cycle) {
      cycle = [];
    }

    for (let i = 0; i < cycle.length; i++) {
      let spectator = Spectator.load(
        Bytes.fromByteArray(ByteArray.fromHexString(cycle[i].toHexString()))
      );

      if (spectator) {
        spectator.auClaimed = rewards.getSpectatorAUClaimed(
          cycle[i] as Address
        );
        spectator.auToClaim = rewards.getSpectatorAUToClaim(
          cycle[i] as Address
        );
        spectator.auEarned = rewards.getSpectatorAUEarned(cycle[i] as Address);

        spectator.save();
      }
    }
    agent.au = rewards.getAgentAUCurrent(agent.address as Address);
    agent.auTotal = rewards.getAgentAUTotal(agent.address as Address);
    agent.cycleSpectators = [];
    agent.save();
  }
}

export function handleSpectated(event: SpectatedEvent): void {
  let entity = new Spectated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.data = event.params.data;
  entity.spectator = event.params.spectator;
  entity.count = event.params.count;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let spectator = Spectator.load(
    Bytes.fromByteArray(
      ByteArray.fromHexString(event.params.spectator.toHexString())
    )
  );
  let rewards = SpectatorRewards.bind(event.address);

  if (!spectator) {
    spectator = new Spectator(
      Bytes.fromByteArray(
        ByteArray.fromHexString(event.params.spectator.toHexString())
      )
    );
    spectator.spectator = event.params.spectator;
    spectator.initialization = rewards.getSpectatorInitialization(
      event.params.spectator
    );
  }
  spectator.save();
  let activity = spectator.activity;

  if (!activity) {
    activity = [];
  }

  let newActivity = new Activity(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );

  newActivity.data = event.params.data;

  let agentResult = rewards.try_getSpectatorAgent(
    event.params.spectator,
    event.params.count.minus(BigInt.fromI32(1))
  );

  if (!agentResult.reverted) {
    newActivity.agent = agentResult.value;
    log.info("new activity", [agentResult.value.toHexString()]);


  newActivity.spectator = event.params.spectator;
  newActivity.blockTimestamp = event.block.timestamp;

  let ipfsHash = event.params.data.split("/").pop();
  if (ipfsHash != null) {
    newActivity.spectateMetadata = ipfsHash;
    SpectateMetadataTemplate.create(ipfsHash);
  }

  newActivity.save();
  activity.push(event.transaction.hash.concatI32(event.logIndex.toI32()));



    let agent = Agent.load(
      Bytes.fromByteArray(
        ByteArray.fromHexString((newActivity.agent as Bytes).toHexString())
      )
    );

    if (!agent) {
      agent = new Agent(
        Bytes.fromByteArray(
          ByteArray.fromHexString((newActivity.agent as Bytes).toHexString())
        )
      );
      agent.address = newActivity.agent as Bytes;
      agent.au = rewards.getAgentAUCurrent(agentResult.value);
      agent.auTotal = rewards.getAgentAUTotal(agentResult.value);
    }
    agent.cycleSpectators = rewards
      .getAgentCycleSpectators(agentResult.value)
      .map<Bytes>((target: Bytes) => target);

    let agentActivity = agent.activity;

    if (!agentActivity) {
      agentActivity = [];
    }

    agentActivity.push(newActivity.id);

    agent.activity = agentActivity;
    agent.save();
  }
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

  let spectator = Spectator.load(
    Bytes.fromByteArray(
      ByteArray.fromHexString(event.params.spectator.toHexString())
    )
  );
  let rewards = SpectatorRewards.bind(event.address);

  if (spectator) {
    spectator.auClaimed = rewards.getSpectatorAUClaimed(event.params.spectator);
    spectator.auToClaim = rewards.getSpectatorAUToClaim(event.params.spectator);

    spectator.save();
  }
}
