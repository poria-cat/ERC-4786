// SPDX-License-Identifier: GPL3.0

pragma solidity ^0.8.0;

import "../Composable.sol";
import "../extensions/ComposableWithERC20.sol";
import "../extensions/ComposableWithERC1155.sol";

contract ComposeableAllTokenType is
    Composable,
    ComposableWithERC20,
    ComposableWithERC1155
{
    // constructor(string memory _tokenName, string memory _tokenSymbol)
    //     Composable(_tokenName, _tokenSymbol)
    // {}
    constructor() {}
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(Composable, ComposableWithERC20, ComposableWithERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
