// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../ERC4786.sol";
import "./IERC4786WithERC20.sol";

abstract contract ERC4786WithERC20 is ERC4786, IERC4786WithERC20 {
    using SafeERC20 for IERC20;

    // (token => erc20 balance)
    mapping(address => mapping(uint256 => mapping(address => uint256))) _balancesOfERC20;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC4786)
        returns (bool)
    {
        return
            interfaceId == type(IERC4786WithERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOfERC20(
        NFT memory targetToken,
        address erc20Address
    ) public view override returns (uint256 balance) {
        balance = _balancesOfERC20[targetToken.tokenAddress][
            targetToken.tokenId
        ][erc20Address];
    }

    function linkERC20(
        address erc20Address,
        uint256 amount,
        NFT memory targetToken,
        bytes memory data
    ) external override {
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be zero address"
        );

        _beforeLinkERC20(msg.sender, erc20Address, amount, targetToken);

        require(
            _isERC721AndExists(targetToken),
            "target/parent token not ERC721 token or not exist"
        );

        uint256 oldBalance = balanceOfERC20(targetToken, erc20Address);
        _updateBalanceOfERC20(targetToken, erc20Address, oldBalance + amount);

        IERC20(erc20Address).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        emit ERC20Linked(msg.sender, erc20Address, amount, targetToken, data);
    }

    function updateERC20Target(
        address erc20Address,
        uint256 amount,
        NFT memory sourceToken,
        NFT memory targetToken,
        bytes memory data
    ) external override {
        require(
            sourceToken.tokenAddress != address(0),
            "source/child token address should not be zero address"
        );
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

        // because have check source token's ownership, so it is a erc721 token
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

        emit ERC20TargetUpdated(erc20Address, amount, sourceToken, targetToken, data);
    }

    // erc20 as source token, erc721 as target token,
    // so it is unlink source token from target token to `to`
    function unlinkERC20(
        address to,
        address erc20Address,
        uint256 amount,
        NFT memory targetToken,
        bytes memory data
    ) external override {
        require(to != address(0), "can't unlink to zero address");

        _beforeUnlinkERC20(to, erc20Address, amount, targetToken);

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

        uint256 oldBalance = balanceOfERC20(targetToken, erc20Address);

        require(oldBalance >= amount, "transfer amount exceeds balance");

        _updateBalanceOfERC20(targetToken, erc20Address, oldBalance - amount);

        IERC20(erc20Address).safeTransfer(to, amount);

        emit ERC20Unlinked(to, erc20Address, amount, targetToken, data);
    }

    function _updateBalanceOfERC20(
        NFT memory targetToken,
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
        NFT memory targetToken
    ) internal virtual {}

    function _beforeUpdateERC20Target(
        address erc20Address,
        uint256 amount,
        NFT memory sourceToken,
        NFT memory targetToken
    ) internal virtual {}

    function _beforeUnlinkERC20(
        address to,
        address erc20Address,
        uint256 amount,
        NFT memory targetToken
    ) internal virtual {}
}
