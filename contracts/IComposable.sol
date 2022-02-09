// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IComposable is IERC165, IERC721Receiver {
    struct ERC721Token {
        address tokenAddress;
        uint256 tokenId;
    }

    /**
     * @dev Emited when sourceToken linked to targetToken.
     */
    event Linked(
        address from,
        ERC721Token sourceToken,
        ERC721Token targetToken,
        bytes data
    );

    /**
     * @dev Emited when sourceToken change target nft to targetToken.
     */
    event TargetUpdated(
        ERC721Token sourceToken,
        ERC721Token targetToken,
        bytes data
    );

    /**
     * Emited when sourceToken unlinked to `to`.
     */
    event Unlinked(address to, ERC721Token sourceToken, bytes data);

    function findRootToken(ERC721Token memory token)
        external
        view
        returns (address rootTokenAddress, uint256 rootTokenId);

    function getTarget(ERC721Token memory sourceToken)
        external
        view
        returns (address tokenAddress, uint256 tokenId);

    function balanceOfERC721(
        ERC721Token memory targetToken,
        ERC721Token memory erc721Token
    ) external view returns (uint256);

    function link(
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken,
        bytes memory data
    ) external;

    function updateTarget(
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken,
        bytes memory data
    ) external;

    function unlink(
        address to,
        ERC721Token memory sourceToken,
        bytes memory data
    ) external;
}
