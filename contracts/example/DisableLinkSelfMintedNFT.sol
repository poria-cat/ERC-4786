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
        address sourceTokenAddress,
        uint256 sourceTokenId,
        address targetTokenAddress,
        uint256 targetTokenId
    ) internal virtual override canNotLink(sourceTokenAddress) {}

    function _beforeUpdateTarget(
        address sourceTokenAddress,
        uint256 sourceTokenId,
        address targetTokenAddress,
        uint256 targetTokenId
    ) internal virtual override canNotLink(sourceTokenAddress) {}
}
