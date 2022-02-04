// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "../Composable.sol";

contract DisableLinkSelfMintedNFT is Composable {
    constructor(string memory _tokenName, string memory _tokenSymbol)
        Composable(_tokenName, _tokenSymbol)
    {}

    modifier canNotLink(address fromTokenAddress) {
        require(
            fromTokenAddress != address(this),
            "can't link this NFT to another NFT"
        );
        _;
    }

    function _beforeLink(
        address from,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) internal virtual override canNotLink(sourceToken.tokenAddress) {}

    function _beforeUpdateTarget(
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) internal virtual override canNotLink(sourceToken.tokenAddress) {}
}
