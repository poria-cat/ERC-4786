// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "../Composable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ComposableWithERC20 is Composable {
    using SafeERC20 for IERC20;

    // (token => erc20 balance)
    mapping(address => mapping(uint256 => mapping(address => uint256))) _balances;

    function linkERC20(
        address erc20Address,
        uint256 value,
        ERC721Token memory targetToken
    ) external {
        require(
            _checkItemsExists(targetToken),
            "target/parent token token not in contract"
        );

        IERC20(erc20Address).safeTransferFrom(msg.sender, address(this), value);

        uint256 oldBalance = balanceOfERC20(targetToken, erc20Address);
        _updateBalanceOfERC20(targetToken, erc20Address, oldBalance + value);
    }

    function updateERC20Target(
        address erc20Address,
        uint256 value,
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
        require(
            balanceOfERC20(sourceToken, erc20Address) >= value,
            "transfer amount exceeds balance"
        );

        uint256 oldSourceBalance = balanceOfERC20(sourceToken, erc20Address);
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
    }

    function unlinkERC20(
        address to,
        address erc20Address,
        uint256 value,
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
        require(
            balanceOfERC20(targetToken, erc20Address) >= value,
            "transfer amount exceeds balance"
        );

        uint256 oldBalance = balanceOfERC20(targetToken, erc20Address);
        _updateBalanceOfERC20(targetToken, erc20Address, oldBalance - value);

        IERC20(erc20Address).safeTransfer(to, value);
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

    function balanceOfERC20(
        ERC721Token memory targetToken,
        address erc20Address
    ) public returns (uint256 balance) {
        balance = _balances[targetToken.tokenAddress][targetToken.tokenId][
            erc20Address
        ];
    }
}
