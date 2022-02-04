// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "../Composable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract ComposableWithERC1155 is Composable {
    struct ERC1155Token {
        address tokenAddress;
        uint256 tokenId;
    }
    // token => erc1155 => balance
    // mapping(address => mapping(uint256 => mapping (address => mapping(uint256 => uint256))) _balances;
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) _balances;

    function linkERC1155(
        ERC1155Token memory sourceToken,
        uint256 amount,
        address targetTokenAddress,
        uint256 targetTokenId
    ) public {
        require(
            _checkItemsExists(targetTokenAddress, targetTokenId),
            "target/parent token token not in contract"
        );

        IERC1155(sourceToken.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            sourceToken.tokenId,
            amount,
            ""
        );

        uint256 oldAmount = balanceOfERC1155(
            targetTokenAddress,
            targetTokenId,
            sourceToken
        );
        _balances[targetTokenAddress][targetTokenId][sourceToken.tokenAddress][
            sourceToken.tokenId
        ] = oldAmount + amount;
    }

    function unlinkERC1155(
        address to,
        ERC1155Token memory sourceToken,
        uint256 amount,
        address targetTokenAddress,
        uint256 targetTokenId
    ) public {
        require(
            _checkItemsExists(targetTokenAddress, targetTokenId),
            "target/parent token token not in contract"
        );
        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            targetTokenAddress,
            targetTokenId
        );
        require(
            ERC721(rootTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller not owner of target token"
        );
        require(
            balanceOfERC1155(targetTokenAddress, targetTokenId, sourceToken) >=
                amount,
            "transfer amount exceeds balance"
        );

        uint256 oldAmount = balanceOfERC1155(
            targetTokenAddress,
            targetTokenId,
            sourceToken
        );
        _balances[targetTokenAddress][targetTokenId][sourceToken.tokenAddress][
            sourceToken.tokenId
        ] = oldAmount - amount;
    }

    function updateERC1155Target(
        address sourceTokenAddress,
        uint256 sourceTokenId,
        ERC1155Token memory sourceERC1155,
        uint256 amount,
        address targetTokenAddress,
        uint256 targetTokenId
    ) public {
        require(
            _checkItemsExists(targetTokenAddress, targetTokenId),
            "target/parent token token not in contract"
        );
        require(
            _checkItemsExists(sourceTokenAddress, sourceTokenId),
            "source/child token token not in contract"
        );

        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            sourceTokenAddress,
            sourceTokenId
        );
        require(
            ERC721(rootTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller not owner of source token"
        );

        uint256 oldSourceBalance = balanceOfERC1155(
            sourceTokenAddress,
            sourceTokenId,
            sourceERC1155
        );

        require(oldSourceBalance >= amount, "transfer amount exceeds balance");

        _balances[sourceTokenAddress][sourceTokenId][
            sourceERC1155.tokenAddress
        ][sourceERC1155.tokenId] = oldSourceBalance - amount;

        uint256 oldTargetBalance = balanceOfERC1155(
            targetTokenAddress,
            targetTokenId,
            sourceERC1155
        );
        _balances[targetTokenAddress][targetTokenId][
            sourceERC1155.tokenAddress
        ][sourceERC1155.tokenId] = oldTargetBalance + amount;
    }

    function balanceOfERC1155(
        address targetTokenAddress,
        uint256 targetTokenId,
        ERC1155Token memory sourceToken
    ) public returns (uint256 balance) {
        balance = _balances[targetTokenAddress][targetTokenId][
            sourceToken.tokenAddress
        ][sourceToken.tokenId];
    }
}
