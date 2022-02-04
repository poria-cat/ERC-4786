// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "../Composable.sol";

abstract contract ComposableWithERC1155 is Composable {
    function linkSemiFungible(
        address semiFungibleTokenAddress,
        uint256 semiFungibleTokenId,
        uint256 amount,
        address targetTokenAddress,
        uint256 targetTokenId
    ) public {

    }
}
