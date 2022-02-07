// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../IComposable.sol";

interface IComposableWithERC1155 is IERC1155Receiver, IComposable {
    struct ERC1155Token {
        address tokenAddress;
        uint256 tokenId;
    }

    event ERC1155Linked(
        address from,
        ERC1155Token erc1155Token,
        uint256 amount,
        ERC721Token targetToken
    );
    event ERC1155TargetUpdated(
        ERC1155Token erc1155Token,
        uint256 amount,
        ERC721Token sourceToken,
        ERC721Token targetToken
    );
    event ERC1155Unlinked(
        address to,
        ERC1155Token erc1155Token,
        uint256 amount,
        ERC721Token targetToken
    );

    function linkERC1155(
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory targetToken
    ) external;

    function updateERC1155Target(
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) external;

    function unlinkERC1155(
        address to,
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory targetToken
    ) external;

    function balanceOfERC1155(
        ERC721Token memory targetToken,
        ERC1155Token memory erc1155Token
    ) external view returns (uint256 balance);
}
