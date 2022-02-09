// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../IComposable.sol";

interface IComposableWithERC1155 is IERC1155Receiver, IComposable {
    // as ERC-1155 token
    struct ERC1155Token {
        address tokenAddress;
        uint256 tokenId;
    }

    /**
     * @dev Emited when link a ERC-1155 token to ERC-721 token
     */
    event ERC1155Linked(
        address from,
        ERC1155Token erc1155Token,
        uint256 amount,
        ERC721Token targetToken,
        bytes data
    );

    /**
     * @dev Emited when ERC-1155 token's target token updated
     */
    event ERC1155TargetUpdated(
        ERC1155Token erc1155Token,
        uint256 amount,
        ERC721Token sourceToken,
        ERC721Token targetToken,
        bytes data
    );

    /**
     * @dev Emited when ERC-1155 token unlinked to `to`
     */
    event ERC1155Unlinked(
        address to,
        ERC1155Token erc1155Token,
        uint256 amount,
        ERC721Token targetToken,
        bytes data
    );

    /**
     * @dev get the balance of ERC-1155 token linked to the target token
     */
    function balanceOfERC1155(
        ERC721Token memory targetToken,
        ERC1155Token memory erc1155Token
    ) external view returns (uint256 balance);

    /**
     * @dev link ERC-1155 token to target token
     * @param erc1155Token link this token to targetToken
     * @param amount ERC-1155 token's amount
     * @param targetToken link to this token
     * @param data information on token changes or other information.
     */
    function linkERC1155(
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory targetToken,
        bytes memory data
    ) external;

    /**
     * @dev update ERC-1155 token's target token
     */
    function updateERC1155Target(
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken,
        bytes memory data
    ) external;

    /**
     * @dev unlink ERC-1155 token to `to`
     */
    function unlinkERC1155(
        address to,
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory targetToken,
        bytes memory data
    ) external;
}
