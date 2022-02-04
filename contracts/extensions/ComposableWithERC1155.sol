// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "../Composable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract ComposableWithERC1155 is Composable {
    // token => erc1155 => balance
    // mapping(address => mapping(uint256 => mapping (address => mapping(uint256 => uint256))) _balances;
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) _balances;

    function linkERC1155(
        address erc1155Address,
        uint256 erc1155TokenId,
        uint256 amount,
        address targetTokenAddress,
        uint256 targetTokenId
    ) public {
        require(
            _checkItemsExists(targetTokenAddress, targetTokenId),
            "target/parent token token not in contract"
        );

        IERC1155(erc1155Address).safeTransferFrom(
            msg.sender,
            address(this),
            erc1155TokenId,
            amount,
            ""
        );

        uint256 oldAmount = balanceOfERC1155(
            targetTokenAddress,
            targetTokenId,
            erc1155Address,
            erc1155TokenId
        );
        _balances[targetTokenAddress][targetTokenId][erc1155Address][
            erc1155TokenId
        ] = oldAmount + amount;
    }

    function unlinkERC1155(
        address to,
        address erc1155Address,
        uint256 erc1155TokenId,
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
            ERC721(targetTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller not owner of target token"
        );
        require(
            balanceOfERC1155(
                targetTokenAddress,
                targetTokenId,
                erc1155Address,
                erc1155TokenId
            ) >= amount,
            "transfer amount exceeds balance"
        );

        uint256 oldAmount = balanceOfERC1155(
            targetTokenAddress,
            targetTokenId,
            erc1155Address,
            erc1155TokenId
        );
        _balances[targetTokenAddress][targetTokenId][erc1155Address][
            erc1155TokenId
        ] = oldAmount - amount;
    }

    function balanceOfERC1155(
        address targetTokenAddress,
        uint256 targetTokenId,
        address erc1155Address,
        uint256 erc1155TokenId
    ) public returns (uint256 balance) {
        balance = _balances[targetTokenAddress][targetTokenId][erc1155Address][
            erc1155TokenId
        ];
    }
}
