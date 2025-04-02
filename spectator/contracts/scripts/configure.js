const { ethers } = require("ethers");
require("dotenv").config();

const accessAbi = require("./../../npc-subgraph/abis/SpectatorAccessControls.json");
const rewardsAbi = require("./../../npc-subgraph/abis/SpectatorRewards.json");
const auAbi = require("./../../npc-subgraph/abis/AU.json");

const provider = new ethers.JsonRpcProvider(
  "https://rpc.testnet.lens.dev",
  37111
);
const wallet = new ethers.Wallet("", provider);
const rewardsAddress = "0xEBF04050D02F3Fa1a9428170e2E42e9608280a12";
const accessAddress = "0xF3e2C0cE4693477CF774D5a6E0369d96Fa4A22eD";
const auAddress = "0x187292F18E282a45d69b0aD20274918ed4f8e855";


(async () => {
  const auContract = new ethers.Contract(auAddress, auAbi, wallet);
  const rewardsContract = new ethers.Contract(
    rewardsAddress,
    rewardsAbi,
    wallet
  );
  const accessContract = new ethers.Contract(
    accessAddress,
    accessAbi,
    wallet
  );

 const tx1 =  await auContract.setRewards(rewardsAddress);
 await tx1.wait();


})();
