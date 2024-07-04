const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const mockCollectionAddress = "0xYourDeployedMockCollectionAddress";

  const MockCollection = await ethers.getContractFactory("MockCollection");
  const mockCollection = await MockCollection.attach(mockCollectionAddress);

  const numOwners = 10;
  const txGenerateOwners = await mockCollection.generateRandomOwners(numOwners);
  await txGenerateOwners.wait();
  console.log(`Generated ${numOwners} random owners.`);

  const numNFTs = 20;
  const txGenerateNFTs = await mockCollection.generateRandomNFTs(numNFTs);
  await txGenerateNFTs.wait();
  console.log(`Generated ${numNFTs} random NFTs.`);

  const owners = await mockCollection.getOwners();
  console.log("Owners:", owners);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
