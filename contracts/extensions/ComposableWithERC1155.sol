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
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory targetToken
    ) public {
        require(
            _checkItemsExists(targetToken),
            "target/parent token token not in contract"
        );

        IERC1155(erc1155Token.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            erc1155Token.tokenId,
            amount,
            ""
        );

        uint256 oldBalance = balanceOfERC1155(targetToken, erc1155Token);
        _setBalanceOfERC1155(targetToken, erc1155Token, oldBalance + amount);
    }

    function updateERC1155Target(
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) public {
        require(
            _checkItemsExists(targetToken),
            "target/parent token token not in contract"
        );
        require(
            _checkItemsExists(sourceToken),
            "source/child token token not in contract"
        );

        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            sourceToken
        );
        require(
            ERC721(rootTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller not owner of source token"
        );

        uint256 oldSourceBalance = balanceOfERC1155(sourceToken, erc1155Token);

        require(oldSourceBalance >= amount, "transfer amount exceeds balance");

        _setBalanceOfERC1155(
            sourceToken,
            erc1155Token,
            oldSourceBalance - amount
        );

        uint256 oldTargetBalance = balanceOfERC1155(targetToken, erc1155Token);
        _setBalanceOfERC1155(
            targetToken,
            erc1155Token,
            oldTargetBalance + amount
        );
    }

    function unlinkERC1155(
        address to,
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory targetToken
    ) public {
        require(
            _checkItemsExists(targetToken),
            "target/parent token token not in contract"
        );
        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            targetToken
        );
        require(
            ERC721(rootTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller not owner of target token"
        );

        uint256 oldBalance = balanceOfERC1155(targetToken, erc1155Token);

        require(oldBalance >= amount, "transfer amount exceeds balance");

        _setBalanceOfERC1155(targetToken, erc1155Token, oldBalance - amount);

        IERC1155(erc1155Token.tokenAddress).safeTransferFrom(
            address(this),
            to,
            erc1155Token.tokenId,
            amount,
            ""
        );
    }

    function _setBalanceOfERC1155(
        ERC721Token memory targetToken,
        ERC1155Token memory erc1155Token,
        uint256 newBalance
    ) private {
        _balances[targetToken.tokenAddress][targetToken.tokenId][
            erc1155Token.tokenAddress
        ][erc1155Token.tokenId] = newBalance;
    }

    function balanceOfERC1155(
        ERC721Token memory targetToken,
        ERC1155Token memory erc1155Token
    ) public view returns (uint256 balance) {
        balance = _balances[targetToken.tokenAddress][targetToken.tokenId][
            erc1155Token.tokenAddress
        ][erc1155Token.tokenId];
    }
}
