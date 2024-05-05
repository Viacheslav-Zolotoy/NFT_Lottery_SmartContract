const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Lottery", function () {
  let lottery;
  let owner;

  beforeEach(async function () {
    const [deployer] = await ethers.getSigners();
    owner = deployer;
    const Lottery = await ethers.getContractFactory("Lottery");
    lottery = await Lottery.deploy(owner.address);
    await lottery.waitForDeployment();
  });

  it("should deploy with the correct owner", async function () {
    expect(await lottery.owner()).to.equal(owner.address);
  });
  it("should allow owner to set reward for burning NFT", async function () {
    const reward = 100;
    await lottery.setRewardForBurning(reward);
    expect(await lottery.rewardForBurnNFT()).to.equal(reward);
  });

  it("should revert if user doesn't have the required NFT", async function () {
    const nftId = 1; // Replace with actual NFT ID
    await expect(lottery.burnNFT(nftId)).to.be.revertedWith(
      "You don't have the required NFT"
    );
  });

  it("should revert if contract doesn't have enough USDT", async function () {
    const reward = await lottery.rewardForBurnNFT();
    await lottery.burnNFT(1);

    await expect(lottery.burnNFT(1)).to.be.revertedWith(
      "Contract doesn't have enough USDT"
    );
  });
  it("should allow owner to start a new lottery", async function () {
    const endTime = Math.floor(Date.now() / 1000) + 60 * 60; // One hour from now
    await lottery.startNewLottery(endTime);
    expect(await lottery.lotteryEndTime()).to.equal(endTime);
  });
});
