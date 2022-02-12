const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

const { constants, expectRevert } = require("@openzeppelin/test-helpers");

describe("Test Composable", function () {
  let accounts;

  let composable;
  let targetNFT;
  let mockNFT;

  const testTokenId0 = 0;
  const testTokenId1 = 1;

  const linkedTokenId0 = 0;
  const linkedTokenId1 = 1;

  before(async function () {
    this.Composable = await ethers.getContractFactory("ERC4786");
    this.TargetNFT = await ethers.getContractFactory("MockNFT");
    this.MockNFT = await ethers.getContractFactory("MockNFT");

    accounts = await ethers.getSigners();
  });

  beforeEach(async function () {
    composable = await this.Composable.deploy();
    await composable.deployed();

    targetNFT = await this.TargetNFT.deploy();
    await targetNFT.deployed();

    mockNFT = await this.MockNFT.deploy();
    await mockNFT.deployed();
  });

  describe("Test link", function () {
    it("link", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockNFT.safeMint(accounts[0].address);
      await mockNFT.safeMint(accounts[0].address);

      await mockNFT.setApprovalForAll(composable.address, true);

      let sourceToken = [mockNFT.address, testTokenId0];
      let targetToken = [targetNFT.address, linkedTokenId1];

      await composable.link(sourceToken, targetToken, []);

      sourceToken = [mockNFT.address, testTokenId1];
      targetToken = [mockNFT.address, testTokenId0];

      await composable.link(sourceToken, targetToken, []);

      const rootToken = await composable.findRootToken([
        mockNFT.address,
        testTokenId1,
      ]);

      expect(rootToken[0]).to.be.eq(targetNFT.address);
      expect(rootToken[1]).to.be.eq(BigNumber.from(linkedTokenId1));
    });

    it("check ancestor", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockNFT.safeMint(accounts[0].address);
      await mockNFT.safeMint(accounts[0].address);

      await mockNFT.setApprovalForAll(composable.address, true);

      const sourceToken = [mockNFT.address, testTokenId1];
      const targetToken = [mockNFT.address, testTokenId0];

      await composable.link(sourceToken, targetToken, []);
      await expectRevert(
        composable.link(targetToken, sourceToken, []),
        "source token is ancestor token"
      );
    });

    it("can't link a NFT that is not owned", async () => {
      await mockNFT.connect(accounts[1]).safeMint(accounts[1].address);
      await mockNFT.setApprovalForAll(composable.address, true);

      await targetNFT.safeMint(accounts[0].address);

      await expectRevert(
        composable.link(
          [mockNFT.address, testTokenId0],
          [targetNFT.address, linkedTokenId0],
          []
        ),
        "ERC721: transfer caller is not owner nor approved"
      );
    });

    it("can't link a NFT that is not owned (approved)", async () => {
      await mockNFT.connect(accounts[1]).safeMint(accounts[1].address);
      await mockNFT.setApprovalForAll(composable.address, true);
      await mockNFT
        .connect(accounts[1])
        .setApprovalForAll(composable.address, true);

      await targetNFT.safeMint(accounts[1].address);

      await expectRevert(
        composable.link(
          [mockNFT.address, testTokenId0],
          [targetNFT.address, linkedTokenId0],
          []
        ),
        "ERC721: transfer from incorrect owner"
      );
    });

    it("can't link to not erc721 token", async () => {
      await mockNFT.safeMint(accounts[0].address);
      await mockNFT.setApprovalForAll(composable.address, true);

      const sourceToken = [mockNFT.address, testTokenId0];
      const targetToken = [composable.address, linkedTokenId0];

      await expectRevert(
        composable.link(sourceToken, targetToken, []),
        "target/parent token not ERC721 token or not exist"
      );
      await expectRevert(
        composable.link(targetToken, sourceToken, []),
        "source/child token not ERC721 token or not exist"
      );
    });
  });

  describe("Test updateTarget", async () => {
    it("updateTarget", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockNFT.safeMint(accounts[0].address);
      await mockNFT.safeMint(accounts[0].address);

      await mockNFT.setApprovalForAll(composable.address, true);
      // link test NFT 0  to target nft 1
      await composable.link(
        [mockNFT.address, testTokenId0],
        [targetNFT.address, linkedTokenId1],
        []
      );

      let root = await composable.findRootToken([
        mockNFT.address,
        testTokenId0,
      ]);

      expect(root[0]).to.be.eq(targetNFT.address);
      expect(root[1]).to.be.eq(BigNumber.from(linkedTokenId1));

      await composable.updateTarget(
        [mockNFT.address, testTokenId0],
        [targetNFT.address, linkedTokenId0],
        []
      );

      root = await composable.findRootToken([mockNFT.address, testTokenId0]);

      expect(root[0]).to.be.eq(targetNFT.address);
      expect(root[1]).to.be.eq(BigNumber.from(linkedTokenId0));
    });

    it("can't updateTarget to descendant token", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockNFT.safeMint(accounts[0].address);
      await mockNFT.safeMint(accounts[0].address);

      await mockNFT.setApprovalForAll(composable.address, true);

      await composable.link(
        [mockNFT.address, testTokenId0],
        [targetNFT.address, linkedTokenId1],
        []
      );

      await expectRevert(
        composable.updateTarget(
          [targetNFT.address, linkedTokenId1],
          [mockNFT.address, testTokenId0],
          []
        ),
        "source token is ancestor token"
      );
    });

    it("can't updateTarget with not own", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockNFT.safeMint(accounts[0].address);

      await mockNFT.setApprovalForAll(composable.address, true);

      await composable.link(
        [mockNFT.address, testTokenId0],
        [targetNFT.address, linkedTokenId1],
        []
      );

      expectRevert(
        composable
          .connect(accounts[1])
          .updateTarget(
            [mockNFT.address, testTokenId0],
            [targetNFT.address, linkedTokenId0],
            []
          ),
        "caller is not owner of source/child token"
      );
    });

    it("can't update target to not erc721 token", async () => {
      await targetNFT.safeMint(accounts[0].address);

      await mockNFT.safeMint(accounts[0].address);

      await mockNFT.setApprovalForAll(composable.address, true);

      await composable.link(
        [mockNFT.address, testTokenId0],
        [targetNFT.address, linkedTokenId0],
        []
      );

      await expectRevert(
        composable.updateTarget(
          [mockNFT.address, testTokenId0],
          [composable.address, linkedTokenId0],
          []
        ),
        "target/parent token not ERC721 token or not exist"
      );
    });
  });

  describe("Test unlink", async () => {
    it("unlink", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockNFT.safeMint(accounts[0].address);
      await mockNFT.safeMint(accounts[0].address);

      await mockNFT.setApprovalForAll(composable.address, true);
      // parent NFT 1 => test NFT 0
      await composable.link(
        [mockNFT.address, testTokenId0],
        [targetNFT.address, linkedTokenId1],
        []
      );
      // parent NFT 1 => test NFT 0 => test NFT 1
      await composable.link(
        [mockNFT.address, testTokenId1],
        [mockNFT.address, testTokenId0],
        []
      );

      await composable.unlink(
        accounts[1].address,
        [mockNFT.address, testTokenId1],
        []
      );
    });

    it("can't unlink not own", async function () {
      await targetNFT.safeMint(accounts[0].address);

      await mockNFT.safeMint(accounts[0].address);
      await mockNFT.setApprovalForAll(composable.address, true);

      await composable.link(
        [mockNFT.address, testTokenId0],
        [targetNFT.address, linkedTokenId0],
        []
      );
      await expectRevert(
        composable
          .connect(accounts[1])
          .unlink(accounts[1].address, [mockNFT.address, testTokenId0], []),
        "caller is not owner of source/child token"
      );
    });

    it("can't unlink not exists in contract's nft", async function () {
      await targetNFT.safeMint(accounts[0].address);

      await mockNFT.safeMint(accounts[0].address);
      await mockNFT.setApprovalForAll(composable.address, true);

      await expectRevert(
        composable.unlink(
          accounts[0].address,
          [mockNFT.address, testTokenId0],
          []
        ),
        "source/child token not in contract"
      );
    });

    it("can't unlink to zero address", async () => {
      await expectRevert(
        composable.unlink(
          constants.ZERO_ADDRESS,
          [mockNFT.address, testTokenId0],
          []
        ),
        "can't unlink to zero address"
      );
    });

    it("complex", async () => {
      await targetNFT.safeMint(accounts[0].address);
      await targetNFT.safeMint(accounts[0].address);

      await mockNFT.safeMint(accounts[0].address);
      await mockNFT.safeMint(accounts[0].address);
      await mockNFT.safeMint(accounts[0].address);

      await mockNFT.setApprovalForAll(composable.address, true);

      // 1. link to contract
      await composable.link(
        [mockNFT.address, testTokenId0],
        [targetNFT.address, linkedTokenId0],
        []
      );
      // 2. link to last
      await composable.link(
        [mockNFT.address, testTokenId1],
        [mockNFT.address, testTokenId0],
        []
      );
      // 3. unlink
      await composable.unlink(
        accounts[0].address,
        [mockNFT.address, testTokenId0],
        []
      );
      // 4. link
      await composable.link(
        [mockNFT.address, 2],
        [mockNFT.address, testTokenId0],
        []
      );
    });
  });
});
