// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title ERC-4786: Compose Common Token With ERC-721 Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-4786
 */
interface IERC4786 is IERC165, IERC721Receiver {
    // Used to represent an ERC-721 Token
    struct NFT {
        address tokenAddress;
        uint256 tokenId;
    }
    /**
     * @dev Emited when sourceToken linked to targetToken.
     * @param from who link `sourceToken` to `targetToken`
     * @param sourceToken starting node, child node
     * @param targetToken ending node, parent node
     * @param data Additional data when link to the targetToken, either the order of the NFT or other information
     */
    event Linked(
        address from,
        NFT sourceToken,
        NFT targetToken,
        bytes data
    );

    /**
     * @dev Emited when sourceToken change target nft to targetToken.
     */
    event TargetUpdated(
        NFT sourceToken,
        NFT targetToken,
        bytes data
    );

    /**
     * @dev Emited when sourceToken unlinked to `to`.
     * @param to unlink sourceToken to one's address
     */
    event Unlinked(address to, NFT sourceToken, bytes data);

    /**
     * @dev find a ERC-721 token's root NFT
     * @param token a ERC-721 token
     */
    function findRootToken(NFT memory token)
        external
        view
        returns (address rootTokenAddress, uint256 rootTokenId);

    /**
     * @dev get a ERC-721 token's target token
     * @param sourceToken  a ERC-721 token
     */
    function getTarget(NFT memory sourceToken)
        external
        view
        returns (address tokenAddress, uint256 tokenId);

    /**
     * @dev for compatibility with balanceOfERC1155, balanceOfERC20.
     * if an ERC-721 token is not linked to a targetToken, then balance is 0, otherwise it is 1
     * @param targetToken linked ERC-721 token
     * @param erc721Token a ERC-721 token
     */
    function balanceOfERC721(
        NFT memory targetToken,
        NFT memory erc721Token
    ) external view returns (uint256);

    /**
     * @dev link a ERC-721 token to another ERC-721 token
     * @param sourceToken link this token to another
     * @param targetToken linked token
     * @param data can as the order of linking to NFT or other information
     */
    function link(
        NFT memory sourceToken,
        NFT memory targetToken,
        bytes memory data
    ) external;

    /**
     * @dev update token's target token
     * @param sourceToken change this token's target token
     * @param targetToken update target token to this token
     * @param data an as the order of NFT or other information
     */
    function updateTarget(
        NFT memory sourceToken,
        NFT memory targetToken,
        bytes memory data
    ) external;

    /**
     * @dev unlink a ERC-721 token to a address
     * @param to unlink token to this address
     * @param sourceToken unlink this token to `to`
     * @param data can as information about token changes or other information
     */
    function unlink(
        address to,
        NFT memory sourceToken,
        bytes memory data
    ) external;
}
