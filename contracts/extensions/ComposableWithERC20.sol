// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "../Composable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ComposableWithERC20 is Composable {
    using SafeERC20 for IERC20;

    mapping(address => mapping(uint256 => uint256)) _balances;

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

        uint256 oldBalance = _balances[targetTokenAddress][targetTokenId];
        _balances[targetTokenAddress][targetTokenId] = oldBalance + value;
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
            ERC721(sourceTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller not owner of source token"
        );
        require(
            _balances[sourceTokenAddress][sourceTokenId] >= value,
            "transfer amount exceeds balance"
        );

        uint256 oldSourceBalance = _balances[sourceTokenAddress][sourceTokenId];
        _balances[sourceTokenAddress][sourceTokenId] = oldSourceBalance - value;

        uint256 oldTargetBalance = _balances[targetTokenAddress][targetTokenId];
        _balances[targetTokenAddress][targetTokenId] = oldTargetBalance + value;
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
            ERC721(targetTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller not owner of target token"
        );
        require(
            balanceOfERC20(targetTokenAddress, targetTokenId) >= value,
            "transfer amount exceeds balance"
        );

        uint256 oldBalance = _balances[targetTokenAddress][targetTokenId];
        _balances[targetTokenAddress][targetTokenId] = oldBalance - value;

        IERC20(erc20Address).safeTransfer(to, value);
    }

    function balanceOfERC20(address targetTokenAddress, uint256 targetTokenId)
        public
        returns (uint256 balance)
    {
        balance = _balances[targetTokenAddress][targetTokenId];
    }
}
