// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "./Composable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ComposableWithERC20 is Composable {
    using SafeERC20 for IERC20;

    mapping(address => mapping(uint256 => uint256)) _balances;

    function linkFungible(
        address fungibleTokenAddress,
        uint256 value,
        address targetTokenAddress,
        uint256 targetTokenId
    ) external {
        require(
            _checkItemsExists(targetTokenAddress, targetTokenId),
            "target/parent token token not in contract"
        );

        IERC20(fungibleTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            value
        );

        _balances[targetTokenAddress][targetTokenId] = value;
    }

    function unlinkFungible(
        address to,
        address fungibleTokenAddress,
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
            balanceOfFungible(targetTokenAddress, targetTokenId) >= value,
            "transfer amount exceeds balance"
        );

        IERC20(fungibleTokenAddress).safeTransfer(to, value);
    }

    function balanceOfFungible(
        address targetTokenAddress,
        uint256 targetTokenId
    ) public returns (uint256 balance) {
        balance = _balances[targetTokenAddress][targetTokenId];
    }
}
