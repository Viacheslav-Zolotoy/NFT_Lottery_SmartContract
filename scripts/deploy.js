const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  // Деплой MockCollection
  const MockCollection = await ethers.getContractFactory("MockCollection");
  console.log("deployer.address: ", deployer.address);

  const mockCollection = await MockCollection.deploy(deployer.address);
  await mockCollection.waitForDeployment();

  console.log("MockCollection deployed to:", mockCollection.target);

  // Деплой Lottery
  const Lottery = await ethers.getContractFactory("Lottery");
  const lottery = await Lottery.deploy(deployer.address);
  await lottery.waitForDeployment();
  console.log("Lottery deployed to:", lottery.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
