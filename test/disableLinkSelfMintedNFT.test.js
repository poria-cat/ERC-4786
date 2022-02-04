const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

describe("Test DisableLinkSelfMintedNFT", function () {
    let accounts;

    let disableLinkSelfMintedNFT;
    let testNFT;

    before(async function () {
        this.DisableLinkSelfMintedNFT = await ethers.getContractFactory("DisableLinkSelfMintedNFT");
        this.TestNFT = await ethers.getContractFactory("TestNFT");

        accounts = await ethers.getSigners();
    });

    beforeEach(async function () {
        disableLinkSelfMintedNFT = await this.DisableLinkSelfMintedNFT.deploy("JustNFT", "JNFT");
        await disableLinkSelfMintedNFT.deployed();

        testNFT = await this.TestNFT.deploy();
        await testNFT.deployed();
    });

    it("try transfer token minted by disableLinkSelfMintedNFT", async function () {
        const linkedTokenId0 = 0;
        const linkedTokenId1 = 1

        await disableLinkSelfMintedNFT.safeMint(accounts[0].address);
        await disableLinkSelfMintedNFT.safeMint(accounts[0].address);

        await disableLinkSelfMintedNFT.setApprovalForAll(
            disableLinkSelfMintedNFT.address,
            true
        );

        await expect(disableLinkSelfMintedNFT.link([disableLinkSelfMintedNFT.address, linkedTokenId1], [disableLinkSelfMintedNFT.address, linkedTokenId0])).to.be.revertedWith(
            "can't link this NFT to another NFT"
        );
    })

});
