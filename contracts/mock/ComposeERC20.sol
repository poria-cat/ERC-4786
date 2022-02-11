// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../ERC4786.sol";
import "../extensions/ERC4786WithERC20.sol";

contract ComposeableERC20Mock is ERC4786WithERC20 {
    constructor() {}
}
