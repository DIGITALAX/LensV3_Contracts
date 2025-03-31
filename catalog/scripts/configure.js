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
const ACTION = "0x3EAB8428d54699d31e9f74F55A83ffd1c76C5380";

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

  // dataContract.setShirtBase("50000000000000000000");
  // dataContract.setHoodieBase("60000000000000000000");
  // dataContract.setVig(5);

  // collectionsContract.setAutographData(dataAddress);
  // collectionsContract.setAutographMarket(marketAddress);

  // marketContract.setAutographCollections(collectionsAddress);
  // marketContract.setAutographData(dataAddress);

  // autoNFTContract.setAutographCollections(collectionsAddress);
  // autoNFTContract.setAutographMarket(marketAddress);

  // catalogNFTContract.setAutographCatalog(catalogAddress);
  // catalogNFTContract.setAutographMarket(marketAddress);

  // // dataContract.addCurrency(BONSAI, "1000000000000000000", "772200000000000000");
  // dataContract.addCurrency(
  //   MONA,
  //   "1000000000000000000",
  //   "411150300000000000000"
  // );

  // controlContract.addAction(ACTION);
  // controlContract.addDesigner(FULFILLER);
  // controlContract.setFulfiller(FULFILLER);
})();
