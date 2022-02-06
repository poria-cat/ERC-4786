const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

const { constants, expectRevert } = require("@openzeppelin/test-helpers");

describe("Test Composable", function () {
  let accounts;

  let composable;
  let testNFT;

  const testTokenId0 = 0;
  const testTokenId1 = 1;

  const linkedTokenId0 = 0;
  const linkedTokenId1 = 1;

  before(async function () {
    this.Composable = await ethers.getContractFactory("Composable");
    this.TestNFT = await ethers.getContractFactory("TestNFT");

    accounts = await ethers.getSigners();
  });

  beforeEach(async function () {
    composable = await this.Composable.deploy("JustNFT", "JNFT");
    await composable.deployed();

    testNFT = await this.TestNFT.deploy();
    await testNFT.deployed();
  });

  describe("Test link", function () {
    it("link NFT in another contract", async function () {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await testNFT.safeMint(accounts[0].address);
      await testNFT.safeMint(accounts[0].address);

      await testNFT.setApprovalForAll(composable.address, true);
      // link test NFT 0  to target nft 1
      await composable.link(
        [testNFT.address, testTokenId0],
        [composable.address, linkedTokenId1]
      );

      const sourceToken = [testNFT.address, testTokenId1];
      const targetToken = [testNFT.address, testTokenId0];
      // link test nft 1 to test nft 0
      await composable.link(sourceToken, targetToken);

      expect(
        (await composable.findRootToken([testNFT.address, testTokenId0]))[1]
      ).to.be.eq(BigNumber.from(linkedTokenId1));
    });

    it("can't link a NFT that is not owned", async function () {
      await testNFT.connect(accounts[1]).safeMint(accounts[1].address);
      await testNFT.setApprovalForAll(composable.address, true);

      await composable.safeMint(accounts[0].address);

      await expectRevert(
        composable.link(
          [testNFT.address, testTokenId0],
          [composable.address, linkedTokenId0]
        ),
        "ERC721: transfer caller is not owner nor approved"
      );
    });

    it("can't link a NFT that is not owned (approved)", async function () {
      await testNFT.connect(accounts[1]).safeMint(accounts[1].address);
      await testNFT.setApprovalForAll(composable.address, true);
      await testNFT
        .connect(accounts[1])
        .setApprovalForAll(composable.address, true);

      await composable.safeMint(accounts[0].address);

      await expectRevert(
        composable.link(
          [testNFT.address, testTokenId0],
          [composable.address, linkedTokenId0]
        ),
        "ERC721: transfer of token that is not own"
      );
    });

    it("can't link a NFT to not exists in composable contract", async function () {
      await testNFT.safeMint(accounts[0].address);
      await testNFT.safeMint(accounts[1].address);
      await testNFT.setApprovalForAll(composable.address, true);

      await composable.safeMint(accounts[0].address);
      await expectRevert(
        composable.link(
          [testNFT.address, testTokenId0],
          [testNFT.address, testTokenId1]
        ),
        "target/parent token not in contract"
      );
    });
  });

  describe("Test updateTarget", async function () {
    it("updateTarget", async function () {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await testNFT.safeMint(accounts[0].address);
      await testNFT.safeMint(accounts[0].address);

      await testNFT.setApprovalForAll(composable.address, true);
      // link test NFT 0  to target nft 1
      await composable.link(
        [testNFT.address, testTokenId0],
        [composable.address, linkedTokenId1]
      );

      let root = await composable.findRootToken([
        testNFT.address,
        testTokenId0,
      ]);

      expect(root[0]).to.be.eq(composable.address);
      expect(root[1]).to.be.eq(BigNumber.from(linkedTokenId1));

      await composable.updateTarget(
        [testNFT.address, testTokenId0],
        [composable.address, linkedTokenId0]
      );

      root = await composable.findRootToken([testNFT.address, testTokenId0]);

      expect(root[0]).to.be.eq(composable.address);
      expect(root[1]).to.be.eq(BigNumber.from(linkedTokenId0));
    });

    it("can't updateTarget to nft that not exist in contract", async function () {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await testNFT.safeMint(accounts[0].address);
      await testNFT.safeMint(accounts[0].address);

      await testNFT.setApprovalForAll(composable.address, true);

      await composable.link(
        [testNFT.address, testTokenId0],
        [composable.address, linkedTokenId1]
      );
      // await composable.updateTarget([testNFT.address, testTokenId0], [testNFT.address, testTokenId1])
      await expectRevert(
        composable.updateTarget(
          [testNFT.address, testTokenId0],
          [testNFT.address, testTokenId1]
        ),
        "target/parent token not in contract"
      );
    });

    it("can't updateTarget with not own", async function () {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await testNFT.safeMint(accounts[0].address);

      await testNFT.setApprovalForAll(composable.address, true);

      await composable.link(
        [testNFT.address, testTokenId0],
        [composable.address, linkedTokenId1]
      );

      expectRevert(
        composable
          .connect(accounts[1])
          .updateTarget(
            [testNFT.address, testTokenId0],
            [composable.address, linkedTokenId0]
          ),
        "caller is not owner of source/child token"
      );
    });
  });

  describe("Test unlink", async function () {
    it("unlink", async function () {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await testNFT.safeMint(accounts[0].address);
      await testNFT.safeMint(accounts[0].address);

      await testNFT.setApprovalForAll(composable.address, true);
      // parent NFT 1 => test NFT 0
      await composable.link(
        [testNFT.address, testTokenId0],
        [composable.address, linkedTokenId1]
      );
      // parent NFT 1 => test NFT 0 => test NFT 1
      await composable.link(
        [testNFT.address, testTokenId1],
        [testNFT.address, testTokenId0]
      );

      await composable.unlink(accounts[1].address, [
        testNFT.address,
        testTokenId1,
      ]);
    });

    it("can't unlink not own", async function () {
      await composable.safeMint(accounts[0].address);

      await testNFT.safeMint(accounts[0].address);
      await testNFT.setApprovalForAll(composable.address, true);

      await composable.link(
        [testNFT.address, testTokenId0],
        [composable.address, linkedTokenId0]
      );
      await expectRevert(
        composable
          .connect(accounts[1])
          .unlink(accounts[1].address, [testNFT.address, testTokenId0]),
        "caller is not owner of source/child token"
      );
    });

    it("can't unlink not exists in contract's nft", async function () {
      await composable.safeMint(accounts[0].address);

      await testNFT.safeMint(accounts[0].address);
      await testNFT.setApprovalForAll(composable.address, true);

      await expectRevert(
        composable.unlink(accounts[0].address, [testNFT.address, testTokenId0]),
        "source/child token not in contract"
      );
    });

    it("can't unlink to zero address", async () => {
      await composable.safeMint(accounts[0].address);

      await testNFT.safeMint(accounts[0].address);
      await testNFT.setApprovalForAll(composable.address, true);

      await expectRevert(
        composable.unlink(constants.ZERO_ADDRESS, [
          testNFT.address,
          testTokenId0,
        ]),
        "can't unlink to zero address"
      );
    });
  });
});
