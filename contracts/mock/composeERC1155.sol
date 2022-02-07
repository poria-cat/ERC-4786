// SPDX-License-Identifier: GPL3.0

pragma solidity ^0.8.0;

import "../Composable.sol";
import "../extensions/ComposableWithERC1155.sol";

contract ComposeableERC1155Mock is ComposableWithERC1155 {
    constructor(string memory _tokenName, string memory _tokenSymbol)
        Composable(_tokenName, _tokenSymbol)
    {}
}
