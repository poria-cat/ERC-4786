// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "hardhat/console.sol";

contract Composable is ERC721 {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    Counters.Counter private _lastTokenId;

    struct Parent {
        address tokenAddress;
        uint256 tokenId;
    }

    // parent(one to one): ((child token address + id) -> (parent token address  + parent id))
    mapping(address => mapping(uint256 => Parent)) _parent;
    // child(one to many): (parent token address + id => Set(keccak256(abi.encode(parent tokenaddress , parent id))))
    mapping(address => mapping(uint256 => EnumerableSet.Bytes32Set)) _children;

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721(_tokenName, _tokenSymbol)
    {}

    function _addChild(
        address fromTokenAddress,
        uint256 fromTokenId,
        address toTokenAddress,
        uint256 toTokenId
    ) private {
        (address parentTokenAddress, uint256 parentTokenId) = getParent(
            fromTokenAddress,
            fromTokenId
        );
        bytes32 fromToken = keccak256(
            abi.encode(fromTokenAddress, fromTokenId)
        );
        if (parentTokenAddress != address(0)) {
            _children[parentTokenAddress][parentTokenId].remove(fromToken);
        }
        _children[toTokenAddress][toTokenId].add(fromToken);
    }

    function _checkItemsExists(address tokenAddress, uint256 tokenId)
        public
        view
        returns (bool)
    {
        if (tokenAddress == address(this)) {
            // just check id existed
            return _exists(tokenId);
        }

        (address parentTokenAddress, ) = getParent(tokenAddress, tokenId);

        // may be a root token, should check have child token or not
        if (parentTokenAddress == address(0)) {
            // if token have no child token, it not in this contract(and it also not a root token)
            return _children[tokenAddress][tokenId].length() > 0;
        }

        // check whether root token in contract
        (address rootTokenAddress, uint256 rootId) = findRootToken(
            tokenAddress,
            tokenId
        );

        if (rootTokenAddress == address(this)) {
            return _exists(rootId);
        } else {
            // root token is not from this contract, so check it have child or not
            return _children[rootTokenAddress][rootId].length() > 0;
        }
    }

    // not allow link this contract's NFT to another NFT
    function _receiveChild(
        address from,
        address fromTokenAddress,
        uint256 fromTokenId,
        address toTokenAddress,
        uint256 toTokenId
    ) private {
        _beforeReceive(
            from,
            fromTokenAddress,
            fromTokenId,
            toTokenAddress,
            toTokenId
        );
        // To prevent malicious use, it is prohibited to associate NFTs that are not in the contract
        require(
            _checkItemsExists(toTokenAddress, toTokenId),
            "parent token not exist"
        );
        require(
            _parent[fromTokenAddress][fromTokenId].tokenAddress == address(0),
            "child token has already been received"
        );

        require(
            ERC721(fromTokenAddress).ownerOf(fromTokenId) == address(this),
            "this contract is not owner of child token"
        );
        _addChild(fromTokenAddress, fromTokenId, toTokenAddress, toTokenId);

        _parent[fromTokenAddress][fromTokenId] = Parent(
            toTokenAddress,
            toTokenId
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        require(
            data.length > 0,
            "data must contain the uint256 tokenId to transfer the child token to."
        );

        (address parentTokenAddress, uint256 parentTokenId) = abi.decode(
            data,
            (address, uint256)
        );

        require(
            parentTokenAddress != address(0),
            "parent token address should not be address(0)"
        );

        _receiveChild(
            from,
            msg.sender,
            tokenId,
            parentTokenAddress,
            parentTokenId
        );

        return IERC721Receiver.onERC721Received.selector;
    }

    function findRootToken(address childTokenAddress, uint256 childTokenId)
        public
        view
        returns (address rootTokenAddress, uint256 rootId)
    {
        (address parentTokenAddress, uint256 parentTokenId) = getParent(
            childTokenAddress,
            childTokenId
        );

        while (
            !(parentTokenAddress == address(0) ||
                parentTokenAddress == address(this))
        ) {
            (parentTokenAddress, parentTokenId) = getParent(
                parentTokenAddress,
                parentTokenId
            );
        }
        return (parentTokenAddress, parentTokenId);
    }

    function getParent(address childTokenAddress, uint256 childTokenId)
        public
        view
        returns (address tokenAddress, uint256 tokenId)
    {
        Parent memory p = _parent[childTokenAddress][childTokenId];
        tokenAddress = p.tokenAddress;
        tokenId = p.tokenId;
    }

    // not allow link this contract's NFT to another NFT
    function link(
        address childTokenAddress,
        uint256 childTokenId,
        address toTokenAddress,
        uint256 toTokenId
    ) public {
        // check child token address whether in contract, if not in, should check child owner, if in contract, should check root owner
        if (
            _checkItemsExists(childTokenAddress, childTokenId) &&
            childTokenAddress != address(this)
        ) {
            // To prevent malicious use of the contract,
            // it is not possible to associate tokens that are not in the contract
            // (except for those already in the contract)
            require(
                _checkItemsExists(toTokenAddress, toTokenId),
                "to token not in contract"
            );

            (address rootTokenAddress, uint256 rootId) = findRootToken(
                childTokenAddress,
                childTokenId
            );
            // maybe root token from other contract NFT, so use down code
            require(
                ERC721(rootTokenAddress).ownerOf(rootId) == msg.sender,
                "sender is not owner of child token"
            );

            _addChild(
                childTokenAddress,
                childTokenId,
                toTokenAddress,
                toTokenId
            );

            _parent[childTokenAddress][childTokenId] = Parent(
                toTokenAddress,
                toTokenId
            );
        } else {
            // on receive data: 1. parent address 2. parent tokenId
            // because receiveChild will use _checkItemsExists to check to Token, so not check here
            ERC721(childTokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                childTokenId,
                abi.encode(toTokenAddress, toTokenId)
            );
        }
    }

    function unlink(
        address to,
        address childTokenAddress,
        uint256 childTokenId
    ) public {
        require(childTokenAddress != address(this), "not child token");
        require(
            _checkItemsExists(childTokenAddress, childTokenId),
            "child token not in contract"
        );

        (address rootTokenAddress, uint256 rootId) = findRootToken(
            childTokenAddress,
            childTokenId
        );
        require(
            ERC721(rootTokenAddress).ownerOf(rootId) == msg.sender,
            "sender is not owner of child token"
        );

        (address parentTokenAddress, uint256 parentTokenId) = getParent(
            childTokenAddress,
            childTokenId
        );

        bytes32 childToken = keccak256(
            abi.encode(childTokenAddress, childTokenId)
        );
        _children[parentTokenAddress][parentTokenId].remove(childToken);

        delete _parent[childTokenAddress][childTokenId];

        ERC721(childTokenAddress).transferFrom(address(this), to, childTokenId);
    }

    function safeMint(address to) public {
        uint256 tokenId = _lastTokenId.current();
        _lastTokenId.increment();
        _safeMint(to, tokenId);
    }

    function _beforeLink(
        address fromTokenAddress,
        uint256 fromTokenId,
        address toTokenAddress,
        uint256 toTokenId
    ) internal virtual {}

    function _beforeReceive(
        address from,
        address fromTokenAddress,
        uint256 fromTokenId,
        address toTokenAddress,
        uint256 toTokenId
    ) internal virtual {}
}
