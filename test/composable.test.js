const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

describe("Test Composable", function () {
    let accounts;

    let composable;
    let testNFT;

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

    it("link NFT in another contract", async function () {
        const testTokenId0 = 0;
        const testTokenId1 = 1;

        const linkedTokenId0 = 0;
        const linkedTokenId1 = 1

        await composable.safeMint(accounts[0].address);
        await composable.safeMint(accounts[0].address);

        await testNFT.safeMint(accounts[0].address);
        await testNFT.safeMint(accounts[0].address);

        await testNFT.setApprovalForAll(
            composable.address,
            true
        );
        // parent NFT 1 => test NFT 0
        await composable.link(testNFT.address, testTokenId0, composable.address, linkedTokenId1);
        // parent NFT 1 => test NFT 0 => test NFT 1
        await composable.link(testNFT.address, testTokenId1, testNFT.address, testTokenId0);


        const root = await composable.findRootToken(testNFT.address, testTokenId0);
        expect(root[1]).to.be.eq(BigNumber.from(testTokenId1));
    });

    it("unlink", async function () {
        const testTokenId0 = 0;
        const testTokenId1 = 1;

        const linkedTokenId0 = 0;
        const linkedTokenId1 = 1

        await composable.safeMint(accounts[0].address);
        await composable.safeMint(accounts[0].address);

        await testNFT.safeMint(accounts[0].address);
        await testNFT.safeMint(accounts[0].address);


        await testNFT.setApprovalForAll(
            composable.address,
            true
        );
        // parent NFT 1 => test NFT 0
        await composable.link(testNFT.address, testTokenId0, composable.address, linkedTokenId1);
        // parent NFT 1 => test NFT 0 => test NFT 1
        await composable.link(testNFT.address, testTokenId1, testNFT.address, testTokenId0);

        await composable.unlink(accounts[1].address, testNFT.address, testTokenId1);
    });

    it("try transfer token minted by composable", async function () {
        const linkedTokenId0 = 0;
        const linkedTokenId1 = 1

        await composable.safeMint(accounts[0].address);
        await composable.safeMint(accounts[0].address);

        await composable.setApprovalForAll(
            composable.address,
            true
        );

        await composable.link(composable.address, linkedTokenId1, composable.address, linkedTokenId0);
    })

});
