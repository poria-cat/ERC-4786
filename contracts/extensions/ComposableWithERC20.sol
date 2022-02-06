// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../Composable.sol";
import "./IComposableWithERC20.sol";

abstract contract ComposableWithERC20 is Composable, IComposableWithERC20 {
    using SafeERC20 for IERC20;

    // (token => erc20 balance)
    mapping(address => mapping(uint256 => mapping(address => uint256))) _balancesOfERC20;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, Composable)
        returns (bool)
    {
        return
            interfaceId == type(IComposableWithERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function linkERC20(
        address erc20Address,
        uint256 amount,
        ERC721Token memory targetToken
    ) external override {
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be zero address"
        );

        _beforeLinkERC20(msg.sender, erc20Address, amount, targetToken);

        require(
            _checkItemsExists(targetToken),
            "target/parent token token not in contract"
        );

        IERC20(erc20Address).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 oldBalance = balanceOfERC20(targetToken, erc20Address);
        _updateBalanceOfERC20(targetToken, erc20Address, oldBalance + amount);

        emit ERC20Linked(msg.sender, erc20Address, amount, targetToken);
    }

    function updateERC20Target(
        address erc20Address,
        uint256 amount,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) external override {
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be zero address"
        );

        _beforeUpdateERC20Target(
            erc20Address,
            amount,
            sourceToken,
            targetToken
        );

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

        uint256 oldSourceBalance = balanceOfERC20(sourceToken, erc20Address);

        require(oldSourceBalance >= amount, "transfer amount exceeds balance");

        _updateBalanceOfERC20(
            sourceToken,
            erc20Address,
            oldSourceBalance - amount
        );

        uint256 oldTargetBalance = balanceOfERC20(targetToken, erc20Address);
        _updateBalanceOfERC20(
            targetToken,
            erc20Address,
            oldTargetBalance + amount
        );

        emit ERC20TargetUpdated(erc20Address, amount, sourceToken, targetToken);
    }

    function unlinkERC20(
        address to,
        address erc20Address,
        uint256 amount,
        ERC721Token memory targetToken
    ) external override {
        require(to != address(0), "can't unlink to zero address");

        _beforeUnlinkERC20(to, erc20Address, amount, targetToken);

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

        uint256 oldBalance = balanceOfERC20(targetToken, erc20Address);

        require(oldBalance >= amount, "transfer amount exceeds balance");

        _updateBalanceOfERC20(targetToken, erc20Address, oldBalance - amount);

        IERC20(erc20Address).safeTransfer(to, amount);

        emit ERC20Unlinked(to, erc20Address, amount, targetToken);
    }

    function _updateBalanceOfERC20(
        ERC721Token memory targetToken,
        address erc20Address,
        uint256 newBalance
    ) internal {
        _balancesOfERC20[targetToken.tokenAddress][targetToken.tokenId][
            erc20Address
        ] = newBalance;
    }

    function _beforeLinkERC20(
        address from,
        address erc20Address,
        uint256 amount,
        ERC721Token memory targetToken
    ) internal virtual {}

    function _beforeUpdateERC20Target(
        address erc20Address,
        uint256 amount,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) internal virtual {}

    function _beforeUnlinkERC20(
        address to,
        address erc20Address,
        uint256 amount,
        ERC721Token memory targetToken
    ) internal virtual {}

    function balanceOfERC20(
        ERC721Token memory targetToken,
        address erc20Address
    ) public view returns (uint256 balance) {
        balance = _balancesOfERC20[targetToken.tokenAddress][
            targetToken.tokenId
        ][erc20Address];
    }
}
