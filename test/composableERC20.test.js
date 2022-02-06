const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

describe("Test ERC20 Composable", function () {
    before(async function () {
        this.Composable = await ethers.getContractFactory("Composable");
        this.TestNFT = await ethers.getContractFactory("TestNFT");

        accounts = await ethers.getSigners();
    });
})