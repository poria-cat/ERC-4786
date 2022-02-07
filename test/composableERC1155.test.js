const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

const { constants, expectRevert } = require("@openzeppelin/test-helpers");

describe("Test ERC1155 Composable", function () {
  let composable;
  let mockERC1155;
  let testNFT;
  let accounts;

  before(async function () {
    this.Composable = await ethers.getContractFactory("ComposeableERC1155Mock");
    this.MockERC1155 = await ethers.getContractFactory("MockERC1155");
    const TestNFT = await ethers.getContractFactory("TestNFT");

    testNFT = await TestNFT.deploy();
    await testNFT.deployed();

    accounts = await ethers.getSigners();
  });

  beforeEach(async function () {
    composable = await this.Composable.deploy("JustNFT", "JNFT");
    await composable.deployed();

    mockERC1155 = await this.MockERC1155.deploy();
    await mockERC1155.deployed();
  });

  describe("Test link", () => {
    it("link", async () => {
      await composable.safeMint(accounts[0].address);
      await mockERC1155.mint(accounts[0].address, 0, 10);

      await mockERC1155.setApprovalForAll(composable.address, true);

      const erc1155Token = [mockERC1155.address, 0];
      const targetToken = [composable.address, 0];

      await composable.linkERC1155(erc1155Token, 5, targetToken);

      expect(
        await composable.balanceOfERC1155(targetToken, erc1155Token)
      ).to.be.eq(BigNumber.from(5));
      expect(await mockERC1155.balanceOf(accounts[0].address, 0)).to.be.eq(
        BigNumber.from(5)
      );
    });

    it("can't link target that not in contact", async () => {
      await mockERC1155.mint(accounts[0].address, 0, 10);

      await mockERC1155.setApprovalForAll(composable.address, true);

      const erc1155Token = [mockERC1155.address, 0];
      const targetToken = [composable.address, 0];

      await expectRevert(
        composable.linkERC1155(erc1155Token, 5, targetToken),
        "target/parent token token not in contract"
      );
    });
  });

  describe("Test updateTarget", () => {
    it("updateTarget", async () => {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await mockERC1155.mint(accounts[0].address, 0, 10);

      await mockERC1155.setApprovalForAll(composable.address, true);

      const erc1155Token = [mockERC1155.address, 0];
      const targetToken = [composable.address, 0];

      await composable.linkERC1155(erc1155Token, 5, targetToken);
      await composable.updateERC1155Target(erc1155Token, 5, targetToken, [
        composable.address,
        1,
      ]);

      expect(
        await composable.balanceOfERC1155(targetToken, erc1155Token)
      ).to.be.eq(BigNumber.from(0));
      expect(
        await composable.balanceOfERC1155([composable.address, 1], erc1155Token)
      ).to.be.eq(BigNumber.from(5));
    });

    it("can't updateTarget with exceeds balance", async () => {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await mockERC1155.mint(accounts[0].address, 0, 10);

      await mockERC1155.setApprovalForAll(composable.address, true);

      const erc1155Token = [mockERC1155.address, 0];
      const targetToken = [composable.address, 0];

      await composable.linkERC1155(erc1155Token, 5, targetToken);

      await expectRevert(
        composable.updateERC1155Target(erc1155Token, 10, targetToken, [
          composable.address,
          1,
        ]),
        "transfer amount exceeds balance"
      );
    });

    it("can't updateTarget with not own", async () => {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await mockERC1155.mint(accounts[0].address, 0, 10);

      await mockERC1155.setApprovalForAll(composable.address, true);

      const erc1155Token = [mockERC1155.address, 0];
      const targetToken = [composable.address, 0];

      await composable.linkERC1155(erc1155Token, 5, targetToken);

      await expectRevert(
        composable
          .connect(accounts[1])
          .updateERC1155Target(erc1155Token, 10, targetToken, [
            composable.address,
            1,
          ]),
        "caller not owner of source token"
      );
    });
  });

  describe("Unlink", () => {
    it("unlink", async () => {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await mockERC1155.mint(accounts[0].address, 0, 10);

      await mockERC1155.setApprovalForAll(composable.address, true);

      const erc1155Token = [mockERC1155.address, 0];
      const targetToken = [composable.address, 0];

      await composable.linkERC1155(erc1155Token, 5, targetToken);

      expect(
        await composable.balanceOfERC1155(targetToken, erc1155Token)
      ).to.be.eq(BigNumber.from(5));

      await composable.unlinkERC1155(
        accounts[0].address,
        erc1155Token,
        5,
        targetToken
      );

      expect(
        await composable.balanceOfERC1155(targetToken, erc1155Token)
      ).to.be.eq(BigNumber.from(0));
    });

    it("can't link if not own target", async () => {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await mockERC1155.mint(accounts[0].address, 0, 10);

      await mockERC1155.setApprovalForAll(composable.address, true);

      const erc1155Token = [mockERC1155.address, 0];
      const targetToken = [composable.address, 0];

      await composable.linkERC1155(erc1155Token, 5, targetToken);

      await expectRevert(
        composable
          .connect(accounts[1])
          .unlinkERC1155(accounts[0].address, erc1155Token, 5, targetToken),
        "caller not owner of target token"
      );
    });

    it("can't unlink exceeds balance", async () => {
      await composable.safeMint(accounts[0].address);
      await composable.safeMint(accounts[0].address);

      await mockERC1155.mint(accounts[0].address, 0, 10);

      await mockERC1155.setApprovalForAll(composable.address, true);

      const erc1155Token = [mockERC1155.address, 0];
      const targetToken = [composable.address, 0];

      await composable.linkERC1155(erc1155Token, 5, targetToken);

      await expectRevert(
        composable.unlinkERC1155(
          accounts[0].address,
          erc1155Token,
          20,
          targetToken
        ),
        "transfer amount exceeds balance"
      );
    });
  });
});
