// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "hardhat/console.sol";

import "./IERC4786.sol";

contract ERC4786 is ERC165, ERC721Holder, IERC4786 {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    Counters.Counter private _lastTokenId;

    // source: starting node, child node
    // target: ending node, parent node

    //target/parent(one to one): ((source/child token address + id) -> (target/parent token address  + target/parent id))
    mapping(address => mapping(uint256 => NFT)) _target;
    // source/child(one to many): (target/parent token address + id => Set(keccak256(abi.encode(target/parent tokenaddress , target/parent id))))
    mapping(address => mapping(uint256 => EnumerableSet.Bytes32Set)) _source;

    constructor() {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC4786).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function findRootToken(NFT memory token)
        public
        view
        override
        returns (address rootTokenAddress, uint256 rootTokenId)
    {
        // if it not have target token, it may be a root token
        if (!_haveTarget(token)) {
            return (token.tokenAddress, token.tokenId);
        }
        (address targetTokenAddress, uint256 targetTokenId) = getTarget(token);

        // find token have no target
        while (_haveTarget(NFT(targetTokenAddress, targetTokenId))) {
            (targetTokenAddress, targetTokenId) = getTarget(
                NFT(targetTokenAddress, targetTokenId)
            );
        }
        return (targetTokenAddress, targetTokenId);
    }

    function getTarget(NFT memory sourceToken)
        public
        view
        override
        returns (address tokenAddress, uint256 tokenId)
    {
        NFT memory t = _target[sourceToken.tokenAddress][
            sourceToken.tokenId
        ];
        tokenAddress = t.tokenAddress;
        tokenId = t.tokenId;
    }

    function balanceOfERC721(
        NFT memory targetToken,
        NFT memory erc721Token
    ) external view override returns (uint256) {
        return
            _source[targetToken.tokenAddress][targetToken.tokenId].contains(
                keccak256(
                    abi.encode(erc721Token.tokenAddress, erc721Token.tokenId)
                )
            )
                ? 1
                : 0;
    }

    function link(
        NFT memory sourceToken,
        NFT memory targetToken,
        bytes memory data
    ) external override {
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be zero address"
        );
        require(
            sourceToken.tokenAddress != address(0),
            "source/child token address should not be zero address"
        );

        _beforeLink(msg.sender, sourceToken, targetToken);

        require(
            _isERC721AndExists(sourceToken),
            "source/child token not ERC721 token or not exist"
        );
        require(
            _isERC721AndExists(targetToken),
            "target/parent token not ERC721 token or not exist"
        );

        require(
            !_isAncestor(targetToken, sourceToken),
            "source token is ancestor token"
        );

        ERC721(sourceToken.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            sourceToken.tokenId
        );

        _addSource(sourceToken, targetToken);
        _addTarget(sourceToken, targetToken);

        emit Linked(msg.sender, sourceToken, targetToken, data);
    }

    function updateTarget(
        NFT memory sourceToken,
        NFT memory targetToken,
        bytes memory data
    ) external override {
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be zero address"
        );
        require(
            sourceToken.tokenAddress != address(0),
            "source/child token address should not be zero address"
        );

        _beforeUpdateTarget(sourceToken, targetToken);

        require(
            _checkItemsExists(sourceToken),
            "source/child token token not in contract"
        );

        require(
            _isERC721AndExists(targetToken),
            "target/parent token not ERC721 token or not exist"
        );

        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            sourceToken
        );

        require(
            _checkItemsExists(NFT(rootTokenAddress, rootTokenId)),
            "wrong token"
        );
        // maybe root token source other contract NFT, so use down code
        require(
            ERC721(rootTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller is not owner of source/child token"
        );

        require(
            !_isAncestor(targetToken, sourceToken),
            "source token is ancestor token"
        );

        (address _targetTokenAddress, uint256 _targetTokenId) = getTarget(
            sourceToken
        );

        _removeSource(
            sourceToken,
            NFT(_targetTokenAddress, _targetTokenId)
        );
        _addSource(sourceToken, targetToken);
        _addTarget(sourceToken, targetToken);

        emit TargetUpdated(sourceToken, targetToken, data);
    }

    function unlink(
        address to,
        NFT memory sourceToken,
        bytes memory data
    ) external override {
        require(to != address(0), "can't unlink to zero address");

        _beforeUnlink(to, sourceToken);

        require(
            _checkItemsExists(sourceToken),
            "source/child token not in contract"
        );

        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            sourceToken
        );

        require(
            _checkItemsExists(NFT(rootTokenAddress, rootTokenId)),
            "wrong token"
        );
        require(
            ERC721(rootTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller is not owner of source/child token"
        );

        (address targetTokenAddress, uint256 targetTokenId) = getTarget(
            sourceToken
        );

        _removeSource(
            sourceToken,
            NFT(targetTokenAddress, targetTokenId)
        );
        _removeTarget(sourceToken);

        ERC721(sourceToken.tokenAddress).safeTransferFrom(
            address(this),
            to,
            sourceToken.tokenId
        );

        emit Unlinked(to, sourceToken, data);
    }

    function _isERC721AndExists(NFT memory token)
        internal
        view
        returns (bool)
    {
        // Although can use try catch here, it's better to check is erc721 token in dapp.
        return
            IERC165(token.tokenAddress).supportsInterface(
                type(IERC721).interfaceId
            )
                ? IERC721(token.tokenAddress).ownerOf(token.tokenId) !=
                    address(0)
                : false;
    }

    function _addSource(
        NFT memory sourceToken,
        NFT memory targetToken
    ) private {
        bytes32 _sourceToken = keccak256(
            abi.encode(sourceToken.tokenAddress, sourceToken.tokenId)
        );
        _source[targetToken.tokenAddress][targetToken.tokenId].add(
            _sourceToken
        );
    }

    function _removeSource(
        NFT memory sourceToken,
        NFT memory targetToken
    ) internal {
        bytes32 _sourceToken = keccak256(
            abi.encode(sourceToken.tokenAddress, sourceToken.tokenId)
        );
        _source[targetToken.tokenAddress][targetToken.tokenId].remove(
            _sourceToken
        );
    }

    function _addTarget(
        NFT memory sourceToken,
        NFT memory targetToken
    ) internal {
        _target[sourceToken.tokenAddress][sourceToken.tokenId] = NFT(
            targetToken.tokenAddress,
            targetToken.tokenId
        );
    }

    function _removeTarget(NFT memory sourceToken) internal {
        delete _target[sourceToken.tokenAddress][sourceToken.tokenId];
    }

    function _checkItemsExists(NFT memory token)
        internal
        view
        returns (bool)
    {
        if (token.tokenAddress == address(0)) {
            return false;
        }

        (address targetTokenAddress, uint256 targetTokenId) = getTarget(token);

        // may be a root token, should check have source/child token or not
        if (targetTokenAddress == address(0)) {
            // if token have no source/child token, it not in this contract(and it also not a root token)
            return _source[token.tokenAddress][token.tokenId].length() > 0;
        } else {
            // target parent is not address(0), so it should have this token
            // return _source[targetTokenAddress][targetTokenId].length() > 0;
            return
                _source[targetTokenAddress][targetTokenId].contains(
                    keccak256(abi.encode(token.tokenAddress, token.tokenId))
                );
        }
    }

    function _haveTarget(NFT memory token)
        internal
        view
        returns (bool)
    {
        (address targetTokenAddress, ) = getTarget(token);

        if (targetTokenAddress == address(0)) {
            return false;
        }
        return true;
    }

    // what is a root token?
    // 1. no target node
    // 2. have source node
    function _isRootToken(NFT memory token)
        internal
        view
        returns (bool)
    {
        if (
            !_haveTarget(token) &&
            _source[token.tokenAddress][token.tokenId].length() > 0
        ) {
            return true;
        }

        return false;
    }

    // check whether ancestorToken is descendantToken's ancestor
    function _isAncestor(
        NFT memory descendantToken,
        NFT memory ancestorToken
    ) internal view returns (bool) {
        if (!_checkItemsExists(descendantToken)) {
            return false;
        }

        if (_isRootToken(descendantToken)) {
            return false;
        }

        (address _targetTokenAddress, uint256 _targetTokenId) = getTarget(
            descendantToken
        );

        bool isAncestor = false;

        while (!isAncestor) {
            if (
                _targetTokenAddress == ancestorToken.tokenAddress &&
                _targetTokenId == ancestorToken.tokenId
            ) {
                isAncestor = true;
            }

            if (
                _isRootToken(NFT(_targetTokenAddress, _targetTokenId))
            ) {
                break;
            }

            (_targetTokenAddress, _targetTokenId) = getTarget(
                NFT(_targetTokenAddress, _targetTokenId)
            );
        }

        return isAncestor;
    }

    function _beforeLink(
        address from,
        NFT memory sourceToken,
        NFT memory targetToken
    ) internal virtual {}

    function _beforeUpdateTarget(
        NFT memory sourceToken,
        NFT memory targetToken
    ) internal virtual {}

    function _beforeUnlink(address to, NFT memory sourceToken)
        internal
        virtual
    {}
}
