// contracts/Collection.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Collection contract", function () {
  let Collection;
  let collection;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    Collection = await ethers.getContractFactory("Collection");
    [owner, addr1, addr2] = await ethers.getSigners();
    collection = await Collection.deploy(owner.address);
    await collection.waitForDeployment();
  });

  it("Should set owner correctly", async function () {
    expect(await collection.owner()).to.equal(owner.address);
  });

  it("Should mint tokens correctly", async function () {
    await collection.safeMint(addr1.address);
    const balance = await collection.balance(addr1.address);
    expect(balance).to.equal(1);
  });

  it("Should burn tokens correctly", async function () {
    await collection.safeMint(addr1.address);
    let tokenId = await collection.getTokenId(addr1.address);
    await collection.burn(tokenId);
    const balance = await collection.balance(addr1.address);
    expect(balance).to.equal(0);
  });

  // Add more tests for other functionalities as needed
});
