// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "../Composable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ComposableWithERC20 is Composable {
    using SafeERC20 for IERC20;

    // (token => erc20 balance)
    mapping(address => mapping(uint256 => mapping(address => uint256))) _balances;

    event ERC20Linked(
        address from,
        address erc20Address,
        uint256 value,
        ERC721Token targetToken
    );
    event ERC20TargetUpdated(
        address erc20Address,
        uint256 value,
        ERC721Token sourceToken,
        ERC721Token targetToken
    );
    event ERC20Unlinked(
        address to,
        address erc20Address,
        uint256 value,
        ERC721Token targetToken
    );

    function linkERC20(
        address erc20Address,
        uint256 value,
        ERC721Token memory targetToken
    ) external {
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be zero address"
        );
        _beforeLinkERC20(msg.sender, erc20Address, value, targetToken);

        require(
            _checkItemsExists(targetToken),
            "target/parent token token not in contract"
        );

        IERC20(erc20Address).safeTransferFrom(msg.sender, address(this), value);

        uint256 oldBalance = balanceOfERC20(targetToken, erc20Address);
        _updateBalanceOfERC20(targetToken, erc20Address, oldBalance + value);

        emit ERC20Linked(msg.sender, erc20Address, value, targetToken);
    }

    function updateERC20Target(
        address erc20Address,
        uint256 value,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) public {
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be zero address"
        );
        _beforeUpdateERC20Target(erc20Address, value, sourceToken, targetToken);

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

        require(oldSourceBalance >= value, "transfer amount exceeds balance");

        _updateBalanceOfERC20(
            sourceToken,
            erc20Address,
            oldSourceBalance - value
        );

        uint256 oldTargetBalance = balanceOfERC20(targetToken, erc20Address);
        _updateBalanceOfERC20(
            targetToken,
            erc20Address,
            oldTargetBalance + value
        );

        emit ERC20TargetUpdated(erc20Address, value, sourceToken, targetToken);
    }

    function unlinkERC20(
        address to,
        address erc20Address,
        uint256 value,
        ERC721Token memory targetToken
    ) public {
        require(to != address(0), "can't unlink to zero address");
        _beforeUnlinkERC20(to, erc20Address, value, targetToken);

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

        require(oldBalance >= value, "transfer amount exceeds balance");

        _updateBalanceOfERC20(targetToken, erc20Address, oldBalance - value);

        IERC20(erc20Address).safeTransfer(to, value);

        emit ERC20Unlinked(to, erc20Address, value, targetToken);
    }

    function _updateBalanceOfERC20(
        ERC721Token memory targetToken,
        address erc20Address,
        uint256 value
    ) internal {
        _balances[targetToken.tokenAddress][targetToken.tokenId][
            erc20Address
        ] = value;
    }

    function _beforeLinkERC20(
        address from,
        address erc20Address,
        uint256 value,
        ERC721Token memory targetToken
    ) internal virtual {}

    function _beforeUpdateERC20Target(
        address erc20Address,
        uint256 value,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) internal virtual {}

    function _beforeUnlinkERC20(
        address to,
        address erc20Address,
        uint256 value,
        ERC721Token memory targetToken
    ) internal virtual {}

    function balanceOfERC20(
        ERC721Token memory targetToken,
        address erc20Address
    ) public returns (uint256 balance) {
        balance = _balances[targetToken.tokenAddress][targetToken.tokenId][
            erc20Address
        ];
    }
}
