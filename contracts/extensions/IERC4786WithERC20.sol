// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../IERC4786.sol";

interface IERC4786WithERC20 is IERC4786 {
    /**
     * @dev Emited when ERC-20 token linked to target token
     */
    event ERC20Linked(
        address from,
        address erc20Address,
        uint256 amount,
        ERC721Token targetToken,
        bytes data
    );

    /**
     * @dev Emited when update ERC-20 token's target token
     */
    event ERC20TargetUpdated(
        address erc20Address,
        uint256 amount,
        ERC721Token sourceToken,
        ERC721Token targetToken,
        bytes data
    );

    /**
     * @dev Emited when unlink ERC-20 token to `to`
     */
    event ERC20Unlinked(
        address to,
        address erc20Address,
        uint256 amount,
        ERC721Token targetToken,
        bytes data
    );

    /**
     * @dev get the balance of ERC-20 token linked to the target token
     */
    function balanceOfERC20(
        ERC721Token memory targetToken,
        address erc20Address
    ) external view returns (uint256 balance);

    /**
     * @dev link ERC-20 token to target token
     */
    function linkERC20(
        address erc20Address,
        uint256 amount,
        ERC721Token memory targetToken,
        bytes memory data
    ) external;

    /**
     * @dev  update ERC-20 token's target token
     */
    function updateERC20Target(
        address erc20Address,
        uint256 amount,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken,
        bytes memory data
    ) external;

    /**
     * @dev unlink ERC-20 token to `to`
     */
    function unlinkERC20(
        address to,
        address erc20Address,
        uint256 amount,
        ERC721Token memory targetToken,
        bytes memory data
    ) external;
}
