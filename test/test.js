const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MockCollection", function () {
  let MockCollection;
  let mockCollection;
  let owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    MockCollection = await ethers.getContractFactory("MockCollection");
    mockCollection = await MockCollection.deploy(owner.address);
    await mockCollection.deployed();
  });

  it("should generate random owners", async function () {
    const numOwners = 10;
    await mockCollection.generateRandomOwners(numOwners);
    const owners = await mockCollection.getOwners();
    expect(owners.length).to.equal(numOwners);
  });

  it("should generate random NFTs", async function () {
    const numNFTs = 20;
    await mockCollection.generateRandomNFTs(numNFTs);
    const nfts = await mockCollection.getNFTs();
    expect(nfts.length).to.equal(numNFTs);
  });
});
