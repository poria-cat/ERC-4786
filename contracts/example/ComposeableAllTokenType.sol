// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../ERC4786.sol";
import "../extensions/ERC4786WithERC20.sol";
import "../extensions/ComposableWithERC1155.sol";

contract ComposeableAllTokenType is
    ERC4786,
    ERC4786WithERC20,
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
        override(ERC4786, ERC4786WithERC20, ComposableWithERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
