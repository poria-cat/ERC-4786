// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    constructor() ERC1155("") {}

    function setURI(string memory newuri) public {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) public {
        _mint(account, id, amount, "");
    }
}
