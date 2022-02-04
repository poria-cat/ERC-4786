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
        address targetTokenAddress,
        uint256 targetTokenId
    ) external {
        require(
            _checkItemsExists(targetTokenAddress, targetTokenId),
            "target/parent token token not in contract"
        );

        IERC20(erc20Address).safeTransferFrom(msg.sender, address(this), value);

        uint256 oldBalance = balanceOfERC20(
            targetTokenAddress,
            targetTokenId,
            erc20Address
        );
        _balances[targetTokenAddress][targetTokenId][erc20Address] =
            oldBalance +
            value;
    }

    function updateERC20Target(
        address sourceTokenAddress,
        uint256 sourceTokenId,
        address erc20Address,
        uint256 value,
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
        require(
            balanceOfERC20(sourceTokenAddress, sourceTokenId, erc20Address) >=
                value,
            "transfer amount exceeds balance"
        );

        uint256 oldSourceBalance = balanceOfERC20(
            sourceTokenAddress,
            sourceTokenId,
            erc20Address
        );
        _balances[sourceTokenAddress][sourceTokenId][erc20Address] =
            oldSourceBalance -
            value;

        uint256 oldTargetBalance = balanceOfERC20(
            targetTokenAddress,
            targetTokenId,
            erc20Address
        );
        _balances[targetTokenAddress][targetTokenId][erc20Address] =
            oldTargetBalance +
            value;
    }

    function unlinkERC20(
        address to,
        address erc20Address,
        uint256 value,
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
            balanceOfERC20(targetTokenAddress, targetTokenId, erc20Address) >=
                value,
            "transfer amount exceeds balance"
        );

        uint256 oldBalance = balanceOfERC20(
            targetTokenAddress,
            targetTokenId,
            erc20Address
        );
        _balances[targetTokenAddress][targetTokenId][erc20Address] =
            oldBalance -
            value;

        IERC20(erc20Address).safeTransfer(to, value);
    }

    function balanceOfERC20(
        address targetTokenAddress,
        uint256 targetTokenId,
        address erc20Address
    ) public returns (uint256 balance) {
        balance = _balances[targetTokenAddress][targetTokenId][erc20Address];
    }
}
