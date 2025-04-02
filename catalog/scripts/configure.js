const { ethers } = require("ethers");
require("dotenv").config();

const controlAbi = require("./../../abis/AutographAccessControl.json");
const marketAbi = require("./../../abis/AutographMarket.json");
const collectionsAbi = require("./../../abis/AutographCollections.json");
const autoNFTAbi = require("./../../abis/AutographNFT.json");
const catalogNFTAbi = require("./../../abis/CatalogNFT.json");
const dataAbi = require("./../../abis/AutographData.json");

const provider = new ethers.JsonRpcProvider(
  "https://rpc.testnet.lens.dev",
  37111
);
const wallet = new ethers.Wallet("", provider);
const collectionsAddress = "0xb8D7431868b9fa64BFd974B3945D11473c41ca71";
const marketAddress = "0xDf5Bbc3259abc34c30EDeA931819b040A5B3199d";
const dataAddress = "0x9b6157F69e42F0c1fC163b8DacdCBA8a2917FfF0";
const autoNFTAddress = "0x97449A383e0f57e82E514196D0B0afE9d95ab319";
const catalogNFTAddress = "0xCD8AE42ef94ecb20322e6c4dcF5072D7c71B7AcE";
const controlAddress = "0xa60174DDD52639D61b0923b9299c099A6bf02DD9";
const catalogAddress = "0x09eb7FdDae34a218E28D1e3606E8BE9D885F7b2A";

const MONA = "0x72ab7C7f3F6FF123D08692b0be196149d4951a41";
const BONSAI = "0x15B58c74A0Ef6D0A593340721055223f38F5721E";
const FULFILLER = "0x3D1f8A6D6584a1672d2817368783B9a2a36ae361";
const ACTION = "0x95F2ad8dC9dfDd52D7E3c94bc780AA93F67f04C8";

(async () => {
  const dataContract = new ethers.Contract(dataAddress, dataAbi, wallet);
  const collectionsContract = new ethers.Contract(
    collectionsAddress,
    collectionsAbi,
    wallet
  );
  const controlContract = new ethers.Contract(
    controlAddress,
    controlAbi,
    wallet
  );
  const autoNFTContract = new ethers.Contract(
    autoNFTAddress,
    autoNFTAbi,
    wallet
  );
  const marketContract = new ethers.Contract(marketAddress, marketAbi, wallet);
  const catalogNFTContract = new ethers.Contract(
    catalogNFTAddress,
    catalogNFTAbi,
    wallet
  );

//  const tx1 =  await dataContract.setShirtBase("50000000000000000000");
//  await tx1.wait();
//   const tx2 = await dataContract.setHoodieBase("60000000000000000000");
//   await tx2.wait();
//   const tx3 = await dataContract.setVig(5);
//   await tx3.wait();

//   const tx4 = await collectionsContract.setAutographData(dataAddress);
//   await tx4.wait();
//   const tx5 = collectionsContract.setAutographMarket(marketAddress);
//   await tx5.wait();

//   const tx6 = await marketContract.setAutographCollections(collectionsAddress);
//   await tx6.wait();
//   const tx7 = await marketContract.setAutographData(dataAddress);
//   await tx7.wait();

//  const tx8 =  await autoNFTContract.setAutographCollections(collectionsAddress);
//  await tx8.wait();
//  const tx9 =  await autoNFTContract.setAutographMarket(marketAddress);
//  await tx9.wait();

//  const tx10 =  await catalogNFTContract.setAutographCatalog(catalogAddress);
//  await tx10.wait();
//  const tx11 =  await catalogNFTContract.setAutographMarket(marketAddress);
//  await tx11.wait();

  // // dataContract.addCurrency(BONSAI, "1000000000000000000", "772200000000000000");
  // dataContract.addCurrency(
  //   MONA,
  //   "1000000000000000000",
  //   "411150300000000000000"
  // );

//  const tx12 =  await controlContract.addAction(ACTION);
//  await tx12.wait();
//  const tx13 =  await controlContract.addDesigner(FULFILLER);
//  await tx13.wait();
//  const tx14 =  await controlContract.setFulfiller(FULFILLER);
//  await tx14.wait();
})();
