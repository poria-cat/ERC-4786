const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

const { constants, expectRevert } = require("@openzeppelin/test-helpers");

describe("Test ERC20 Composable", function () {
  let composable;
  let mockERC1155;
  //   let testNFT;
  let accounts;

  before(async function () {
    this.Composable = await ethers.getContractFactory("ComposeableERC1155Mock");
    this.MockERC1155 = await ethers.getContractFactory("MockERC1155");
    // this.TestNFT = await ethers.getContractFactory("TestNFT");

    accounts = await ethers.getSigners();
  });

  beforeEach(async function () {
    composable = await this.Composable.deploy("JustNFT", "JNFT");
    await composable.deployed();

    mockERC1155 = await this.MockERC1155.deploy();
    await mockERC1155.deployed();

    // testNFT = await this.TestNFT.deploy();
    // await testNFT.deployed();
  });

  describe("Test link", async () => {
    it("link", async () => {});
  });
});
