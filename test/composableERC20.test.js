const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

describe("Test ERC20 Composable", function () {
  let composable;
  let mockERC20;
  let accounts;

  const linkedTokenId0 = 0;
  const linkedTokenId1 = 1;

  const mintedERC20 = BigNumber.from(`${1e18 * 100}`);

  before(async function () {
    this.Composable = await ethers.getContractFactory("ComposeableERC20Mock");
    this.MockERC20 = await ethers.getContractFactory("MockERC20");

    accounts = await ethers.getSigners();
  });

  beforeEach(async function () {
    composable = await this.Composable.deploy("JustNFT", "JNFT");
    await composable.deployed();

    mockERC20 = await this.MockERC20.deploy();
    await mockERC20.deployed();
  });

  describe("Test link erc20", () => {
    it("link", async () => {
      await composable.safeMint(accounts[0].address);
      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      await composable.linkERC20(mockERC20.address, mintedERC20, [
        composable.address,
        0,
      ]);
    });
  });
});
