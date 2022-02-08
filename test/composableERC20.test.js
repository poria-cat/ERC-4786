const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

const { constants, expectRevert } = require("@openzeppelin/test-helpers");

describe("Test ERC20 Composable", function () {
  let composable;
  let mockERC20;
  let targetNFT;
  let mockNFT;

  let accounts;

  const linkedTokenId0 = 0;
  const linkedTokenId1 = 1;

  const mintedERC20 = BigNumber.from(`${1e18 * 100}`);

  before(async function () {
    this.Composable = await ethers.getContractFactory("ComposeableERC20Mock");
    this.MockERC20 = await ethers.getContractFactory("MockERC20");
    this.TargetNFT = await ethers.getContractFactory("MockNFT");
    this.MockNFT = await ethers.getContractFactory("MockNFT");

    accounts = await ethers.getSigners();
  });

  beforeEach(async function () {
    composable = await this.Composable.deploy();
    await composable.deployed();

    mockERC20 = await this.MockERC20.deploy();
    await mockERC20.deployed();

    targetNFT = await this.TargetNFT.deploy();
    await targetNFT.deployed();

    mockNFT = await this.MockNFT.deploy();
    await mockNFT.deployed();
  });

  describe("Test link", () => {
    it("link", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken = [targetNFT.address, linkedTokenId0];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken);

      expect(
        await composable.balanceOfERC20(targetToken, mockERC20.address)
      ).to.be.eq(mintedERC20);
    });

    it("link to source token", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await mockNFT.safeMint(accounts[0].address);
      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);
      await mockNFT.setApprovalForAll(composable.address, true);

      await composable.link([mockNFT.address, 0], [targetNFT.address, 0]);

      const targetToken = [targetNFT.address, linkedTokenId0];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken);

      expect(
        await composable.balanceOfERC20(targetToken, mockERC20.address)
      ).to.be.eq(mintedERC20);
    });

    it("can't link with exceeds balance", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await mockERC20.mint(accounts[0].address, BigNumber.from(`${10 * 1e18}`));

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken = [targetNFT.address, linkedTokenId0];

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

  describe("Test updateTarget", () => {
    it("updateERC20Target", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken1 = [targetNFT.address, linkedTokenId0];
      const targetToken2 = [targetNFT.address, linkedTokenId1];

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

    it("update target token with source token's erc20", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await mockNFT.safeMint(accounts[0].address);
      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);
      await mockNFT.setApprovalForAll(composable.address, true);

      const targetToken = [targetNFT.address, linkedTokenId0];
      const sourceToken = [mockNFT.address, 0];

      await composable.link(sourceToken, targetToken);
      await composable.linkERC20(mockERC20.address, mintedERC20, sourceToken);

      await composable.updateERC20Target(
        mockERC20.address,
        mintedERC20,
        sourceToken,
        targetToken
      );
    });

    it("can't updateTarget with exceeds balance ", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken1 = [targetNFT.address, linkedTokenId0];
      const targetToken2 = [targetNFT.address, linkedTokenId1];

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
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken1 = [targetNFT.address, linkedTokenId0];
      const targetToken2 = [targetNFT.address, linkedTokenId1];

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

    it("target token address can't be zero address", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockERC20.mint(accounts[0].address, mintedERC20);
      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken1 = [targetNFT.address, linkedTokenId0];
      const targetToken2 = [constants.ZERO_ADDRESS, linkedTokenId1];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken1);
      await expectRevert(
        composable.updateERC20Target(
          mockERC20.address,
          mintedERC20,
          targetToken1,
          targetToken2
        ),
        "target/parent token address should not be zero address"
      );
    });

    it("can't updateTarget to not a erc721 token", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await mockNFT.safeMint(accounts[0].address);

      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken1 = [targetNFT.address, linkedTokenId0];
      const targetToken2 = [composable.address, linkedTokenId0];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken1);
      await expectRevert(
        composable.updateERC20Target(
          mockERC20.address,
          mintedERC20,
          targetToken1,
          targetToken2
        ),
        "target/parent token not ERC721 token or not exist"
      );
    });
  });

  describe("Test unlink", async () => {
    it("unlink", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken = [targetNFT.address, linkedTokenId0];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken);
      await composable.unlinkERC20(
        accounts[0].address,
        mockERC20.address,
        mintedERC20,
        targetToken
      );

      expect(
        await composable.balanceOfERC20(targetToken, mockERC20.address)
      ).to.be.eq(BigNumber.from(0));
      expect(await mockERC20.balanceOf(accounts[0].address)).to.be.eq(
        mintedERC20
      );
    });

    it("can't unlink if not own target token", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken = [targetNFT.address, linkedTokenId0];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken);

      await expectRevert(
        composable
          .connect(accounts[1])
          .unlinkERC20(
            accounts[0].address,
            mockERC20.address,
            mintedERC20,
            targetToken
          ),
        "caller not owner of target token"
      );
    });

    it("can't unlink exceeds balance", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await mockERC20.mint(accounts[0].address, mintedERC20);

      await mockERC20.approve(composable.address, mintedERC20);

      const targetToken = [targetNFT.address, linkedTokenId0];

      await composable.linkERC20(mockERC20.address, mintedERC20, targetToken);

      await expectRevert(
        composable.unlinkERC20(
          accounts[0].address,
          mockERC20.address,
          BigNumber.from(`${110 * 1e18}`),
          targetToken
        ),
        "transfer amount exceeds balance"
      );
    });
  });
});
