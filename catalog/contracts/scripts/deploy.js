const { Provider, Wallet, ContractFactory } = require("zksync-ethers");
require("dotenv").config();
const fs = require("fs");

const provider = new Provider("https://rpc.testnet.lens.dev", 37111);
const wallet = new Wallet("", provider);

(async () => {
  const acJson = JSON.parse(
    fs.readFileSync(
      "./../../contracts/zkout/AutographAccessControl.sol/AutographAccessControl.json",
      "utf8"
    )
  );
  const acContractFactory = new ContractFactory(
    acJson.abi,
    acJson.bytecode.object,
    wallet
  );
  const acContract = await acContractFactory.deploy();
  console.log("AC Contract deployed at:", acContract.target);

  const autoNFTJson = JSON.parse(
    fs.readFileSync(
      "./../../contracts/zkout/AutographNFT.sol/AutographNFT.json",
      "utf8"
    )
  );
  const autoNFTContractFactory = new ContractFactory(
    autoNFTJson.abi,
    autoNFTJson.bytecode.object,
    wallet
  );
  const autoNFTContract = await autoNFTContractFactory.deploy(
    acContract.target
  );
  console.log("Auto NFT Contract deployed at:", autoNFTContract.target);

  const catalogNFTJson = JSON.parse(
    fs.readFileSync(
      "./../../contracts/zkout/CatalogNFT.sol/CatalogNFT.json",
      "utf8"
    )
  );
  const catalogNFTContractFactory = new ContractFactory(
    catalogNFTJson.abi,
    catalogNFTJson.bytecode.object,
    wallet
  );
  const catalogNFTContract = await catalogNFTContractFactory.deploy(
    acContract.target
  );
  console.log("Catalog NFT Contract deployed at:", catalogNFTContract.target);

  const autoCatalogJson = JSON.parse(
    fs.readFileSync(
      "./../../contracts/zkout/AutographCatalog.sol/AutographCatalog.json",
      "utf8"
    )
  );
  const autoCatalogContractFactory = new ContractFactory(
    autoCatalogJson.abi,
    autoCatalogJson.bytecode.object,
    wallet
  );
  const autoCatalogContract = await autoCatalogContractFactory.deploy(
    acContract.target,
    catalogNFTContract.target
  );
  console.log("Auto Catalog Contract deployed at:", autoCatalogContract.target);

  const autographDataJson = JSON.parse(
    fs.readFileSync(
      "./../../contracts/zkout/AutographData.sol/AutographData.json",
      "utf8"
    )
  );
  const autographDataContractFactory = new ContractFactory(
    autographDataJson.abi,
    autographDataJson.bytecode.object,
    wallet
  );
  const autographDataContract = await autographDataContractFactory.deploy(
    acContract.target
  );
  console.log("Auto Data Contract deployed at:", autographDataContract.target);

  const autoCollectionsJson = JSON.parse(
    fs.readFileSync(
      "./../../contracts/zkout/AutographCollections.sol/AutographCollections.json",
      "utf8"
    )
  );
  const autoCollectionsContractFactory = new ContractFactory(
    autoCollectionsJson.abi,
    autoCollectionsJson.bytecode.object,
    wallet
  );
  const autoCollectionsContract = await autoCollectionsContractFactory.deploy(
    acContract.target,
    autoCollectionsContract.target
  );
  console.log(
    "Auto Collections Contract deployed at:",
    autoCollectionsContract.target
  );

  const autoMarketJson = JSON.parse(
    fs.readFileSync(
      "./../../contracts/zkout/AutographMarket.sol/AutographMarket.json",
      "utf8"
    )
  );
  const autoMarketContractFactory = new ContractFactory(
    autoMarketJson.abi,
    autoMarketJson.bytecode.object,
    wallet
  );
  const autoMarketContract = await autoMarketContractFactory.deploy(
    acContract.target,
    autoCatalogContract.target,
    autoCollectionsContract.target,
    autoNFTContract.target,
    catalogNFTContract.target,
    autographDataContract.target
  );
  console.log("Auto Market Contract deployed at:", autoMarketContract.target);

  const autographActionJson = JSON.parse(
    fs.readFileSync(
      "./../../contracts/zkout/AutographAction.sol/AutographAction.json",
      "utf8"
    )
  );
  const autoActionContractFactory = new ContractFactory(
    autographActionJson.abi,
    autographActionJson.bytecode.object,
    wallet
  );
  const autoActionContract = await autoActionContractFactory.deploy(
    acContract.target,
    autoCollectionsContract.target,
    autoMarketContract.target,
    autoCatalogContract.target
  );
  console.log("Auto Action Contract deployed at:", autoActionContract.target);
})();
