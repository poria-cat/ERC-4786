// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "../ComposableNFT.sol";

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
        address fromTokenAddress,
        uint256 fromTokenId,
        address toTokenAddress,
        uint256 toTokenId
    ) internal virtual override canNotLink(fromTokenAddress) {}

    function _beforeReceive(
        address from,
        address fromTokenAddress,
        uint256 fromTokenId,
        address toTokenAddress,
        uint256 toTokenId
    ) internal virtual override canNotLink(fromTokenAddress) {}
}
