// SPDX-License-Identifier: GPL3.0

pragma solidity ^0.8.0;

import "../Composable.sol";
import "../extensions/ComposableWithERC20.sol";

contract ComposeableERC20Mock is ComposableWithERC20 {
    constructor(string memory _tokenName, string memory _tokenSymbol)
        Composable(_tokenName, _tokenSymbol)
    {}

    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     virtual
    //     override(Composable, ComposableWithERC20)
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId);
    // }
}
