// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../IERC4786.sol";

interface IERC4786WithERC1155 is IERC1155Receiver, IERC4786 {
    /**
     * @dev Emited when link a ERC-1155 token to ERC-721 token
     */
    event ERC1155Linked(
        address from,
        NFT erc1155Token,
        uint256 amount,
        NFT targetToken,
        bytes data
    );

    /**
     * @dev Emited when ERC-1155 token's target token updated
     */
    event ERC1155TargetUpdated(
        NFT erc1155Token,
        uint256 amount,
        NFT sourceToken,
        NFT targetToken,
        bytes data
    );

    /**
     * @dev Emited when ERC-1155 token unlinked to `to`
     */
    event ERC1155Unlinked(
        address to,
        NFT erc1155Token,
        uint256 amount,
        NFT targetToken,
        bytes data
    );

    /**
     * @dev get the balance of ERC-1155 token linked to the target token
     */
    function balanceOfERC1155(NFT memory targetToken, NFT memory erc1155Token)
        external
        view
        returns (uint256 balance);

    /**
     * @dev link ERC-1155 token to target token
     * @param erc1155Token link this token to targetToken
     * @param amount ERC-1155 token's amount
     * @param targetToken link to this token
     * @param data information on token changes or other information.
     */
    function linkERC1155(
        NFT memory erc1155Token,
        uint256 amount,
        NFT memory targetToken,
        bytes memory data
    ) external;

    /**
     * @dev update ERC-1155 token's target token
     */
    function updateERC1155Target(
        NFT memory erc1155Token,
        uint256 amount,
        NFT memory sourceToken,
        NFT memory targetToken,
        bytes memory data
    ) external;

    /**
     * @dev unlink ERC-1155 token to `to`
     */
    function unlinkERC1155(
        address to,
        NFT memory erc1155Token,
        uint256 amount,
        NFT memory targetToken,
        bytes memory data
    ) external;
}
