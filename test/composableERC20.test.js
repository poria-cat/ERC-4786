const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

const { constants, expectRevert } = require("@openzeppelin/test-helpers");

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

      const targetToken = [composable.address, linkedTokenId0];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken);

      expect(
        await composable.balanceOfERC20(targetToken, mockERC20.address)
      ).to.be.eq(mintedERC20);
    });

    it("can't link with exceeds balance", async () => {
      await composable.safeMint(accounts[0].address);
      await mockERC20.mint(accounts[0].address, BigNumber.from(`${10 * 1e18}`));

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken = [composable.address, linkedTokenId0];

      await expectRevert(
        composable.linkERC20(mockERC20.address, mintedERC20, targetToken),
        "ERC20: transfer amount exceeds balance"
      );
    });

    it("target token address can't be zero address", async () => {
      await mockERC20.mint(accounts[0].address, BigNumber.from(`${10 * 1e18}`));

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken = [constants.ZERO_ADDRESS, linkedTokenId0];
      await expectRevert(
        composable.linkERC20(mockERC20.address, mintedERC20, targetToken),
        "target/parent token address should not be zero address"
      );
    });
  });

  describe("Test updateERC20Target", () => {
    it("updateERC20Target", async () => {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken1 = [composable.address, linkedTokenId0];
      const targetToken2 = [composable.address, linkedTokenId1];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken1);
      await composable.updateERC20Target(
        mockERC20.address,
        mintedERC20,
        targetToken1,
        targetToken2
      );

      expect(
        await composable.balanceOfERC20(targetToken1, mockERC20.address)
      ).to.be.eq(BigNumber.from(0));
      expect(
        await composable.balanceOfERC20(targetToken2, mockERC20.address)
      ).to.be.eq(mintedERC20);
    });

    it("can't updateTarget with exceeds balance ", async () => {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken1 = [composable.address, linkedTokenId0];
      const targetToken2 = [composable.address, linkedTokenId1];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken1);
      await expectRevert(
        composable.updateERC20Target(
          mockERC20.address,
          BigNumber.from(`${110 * 1e18}`),
          targetToken1,
          targetToken2
        ),
        "transfer amount exceeds balance"
      );
    });

    it("can't updateTarget with not own", async () => {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken1 = [composable.address, linkedTokenId0];
      const targetToken2 = [composable.address, linkedTokenId1];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken1);
      await expectRevert(
        composable
          .connect(accounts[1])
          .updateERC20Target(
            mockERC20.address,
            mintedERC20,
            targetToken1,
            targetToken2
          ),
        "caller not owner of source token"
      );
    });
  });
});