// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "../IComposable.sol";

interface IComposableWithERC20 is IComposable {
    event ERC20Linked(
        address from,
        address erc20Address,
        uint256 amount,
        ERC721Token targetToken
    );
    event ERC20TargetUpdated(
        address erc20Address,
        uint256 amount,
        ERC721Token sourceToken,
        ERC721Token targetToken
    );
    event ERC20Unlinked(
        address to,
        address erc20Address,
        uint256 amount,
        ERC721Token targetToken
    );

    function linkERC20(
        address erc20Address,
        uint256 amount,
        ERC721Token memory targetToken
    ) external;

    function updateERC20Target(
        address erc20Address,
        uint256 amount,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) external;

    function unlinkERC20(
        address to,
        address erc20Address,
        uint256 amount,
        ERC721Token memory targetToken
    ) external;
}
