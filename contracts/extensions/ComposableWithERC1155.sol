// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "../Composable.sol";
import "./IComposableWithERC1155.sol";

abstract contract ComposableWithERC1155 is
    ERC1155Holder,
    Composable,
    IComposableWithERC1155
{
    // token => erc1155 => balance
    // mapping(address => mapping(uint256 => mapping (address => mapping(uint256 => uint256))) _balances;
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) _balancesOfERC1155;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155Receiver, Composable)
        returns (bool)
    {
        return
            interfaceId == type(IComposableWithERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOfERC1155(
        ERC721Token memory targetToken,
        ERC1155Token memory erc1155Token
    ) public view override returns (uint256 balance) {
        balance = _balancesOfERC1155[targetToken.tokenAddress][
            targetToken.tokenId
        ][erc1155Token.tokenAddress][erc1155Token.tokenId];
    }

    function linkERC1155(
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory targetToken
    ) external override {
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be zero address"
        );

        _beforeLinkERC1155(msg.sender, erc1155Token, amount, targetToken);

        require(
            _isERC721AndExists(targetToken),
            "target/parent token not ERC721 token or not exist"
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

        emit ERC1155Linked(msg.sender, erc1155Token, amount, targetToken);
    }

    function updateERC1155Target(
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) external override {
        require(
            sourceToken.tokenAddress != address(0),
            "source/child token address should not be zero address"
        );
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be zero address"
        );

        _beforeUpdateERC1155Target(
            erc1155Token,
            amount,
            sourceToken,
            targetToken
        );

        require(
            _isERC721AndExists(targetToken),
            "target/parent token not ERC721 token or not exist"
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

        emit ERC1155TargetUpdated(
            erc1155Token,
            amount,
            sourceToken,
            targetToken
        );
    }

    function unlinkERC1155(
        address to,
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory targetToken
    ) external override {
        require(to != address(0), "can't unlink to zero address");

        _beforeUnlinkERC1155(to, erc1155Token, amount, targetToken);

        require(
            _isERC721AndExists(targetToken),
            "target/parent token not ERC721 token or not exist"
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

        emit ERC1155Unlinked(to, erc1155Token, amount, targetToken);
    }

    function _setBalanceOfERC1155(
        ERC721Token memory targetToken,
        ERC1155Token memory erc1155Token,
        uint256 newBalance
    ) internal {
        _balancesOfERC1155[targetToken.tokenAddress][targetToken.tokenId][
            erc1155Token.tokenAddress
        ][erc1155Token.tokenId] = newBalance;
    }

    function _beforeLinkERC1155(
        address from,
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory targetToken
    ) internal virtual {}

    function _beforeUpdateERC1155Target(
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) internal virtual {}

    function _beforeUnlinkERC1155(
        address to,
        ERC1155Token memory erc1155Token,
        uint256 amount,
        ERC721Token memory targetToken
    ) internal virtual {}
}
