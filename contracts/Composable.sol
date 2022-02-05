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

    struct ERC721Token {
        address tokenAddress;
        uint256 tokenId;
    }

    // source: starting node, child node
    // target: ending node, parent node

    //target/parent(one to one): ((source/child token address + id) -> (target/parent token address  + target/parent id))
    mapping(address => mapping(uint256 => ERC721Token)) _target;
    // source/child(one to many): (target/parent token address + id => Set(keccak256(abi.encode(target/parent tokenaddress , target/parent id))))
    mapping(address => mapping(uint256 => EnumerableSet.Bytes32Set)) _source;

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721(_tokenName, _tokenSymbol)
    {}

    function _addSource(
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) private {
        bytes32 _sourceToken = keccak256(
            abi.encode(sourceToken.tokenAddress, sourceToken.tokenId)
        );
        if (targetToken.tokenAddress != address(0)) {
            _source[targetToken.tokenAddress][targetToken.tokenId].remove(
                _sourceToken
            );
        }
        _source[targetToken.tokenAddress][targetToken.tokenId].add(
            _sourceToken
        );
    }

    function _checkItemsExists(ERC721Token memory token)
        public
        view
        returns (bool)
    {
        if (token.tokenAddress == address(this)) {
            // just check id existed
            return _exists(token.tokenId);
        }

        (address targetTokenAddress, uint256 targetTokenId) = getTarget(token);

        // may be a root token, should check have source/child token or not
        if (targetTokenAddress == address(0)) {
            // if token have no source/child token, it not in this contract(and it also not a root token)
            return _source[token.tokenAddress][token.tokenId].length() > 0;
        } else {
            // target parent is not address(0), so it should have child/source token
            return _source[targetTokenAddress][targetTokenId].length() > 0;
        }
    }

    function _checkRootExists(ERC721Token memory rootToken)
        public
        view
        returns (bool)
    {
        if (rootToken.tokenAddress == address(0)) {
            return false;
        }

        if (rootToken.tokenAddress == address(this)) {
            return _exists(rootToken.tokenId);
        } else {
            // root token is not source this contract, so check it have source/child or not
            return
                _source[rootToken.tokenAddress][rootToken.tokenId].length() > 0;
        }
    }

    function _haveTarget(ERC721Token memory token) private view returns (bool) {
        (address targetTokenAddress, ) = getTarget(token);

        if (targetTokenAddress == address(0)) {
            return false;
        }
        return true;
    }

    function findRootToken(ERC721Token memory token)
        public
        view
        returns (address rootTokenAddress, uint256 rootTokenId)
    {
        // if it not have target token, it may be a root token
        if (!_haveTarget(token)) {
            return (token.tokenAddress, token.tokenId);
        }
        (address targetTokenAddress, uint256 targetTokenId) = getTarget(token);

        // find token have no target
        while (_haveTarget(ERC721Token(targetTokenAddress, targetTokenId))) {
            (targetTokenAddress, targetTokenId) = getTarget(
                ERC721Token(targetTokenAddress, targetTokenId)
            );
        }
        return (targetTokenAddress, targetTokenId);
    }

    function getTarget(ERC721Token memory sourceToken)
        public
        view
        returns (address tokenAddress, uint256 tokenId)
    {
        ERC721Token memory t = _target[sourceToken.tokenAddress][
            sourceToken.tokenId
        ];
        tokenAddress = t.tokenAddress;
        tokenId = t.tokenId;
    }

    function link(
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) public {
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be address(0)"
        );

        _beforeLink(msg.sender, sourceToken, targetToken);
        // To prevent malicious use, it is prohibited to associate NFTs that are not in the contract
        require(
            _checkItemsExists(targetToken),
            "target/parent token not exist"
        );
        require(
            _target[sourceToken.tokenAddress][sourceToken.tokenId]
                .tokenAddress == address(0),
            "source/child token has already been received"
        );

        ERC721(sourceToken.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            sourceToken.tokenId
        );

        _addSource(sourceToken, targetToken);

        _target[sourceToken.tokenAddress][sourceToken.tokenId] = ERC721Token(
            targetToken.tokenAddress,
            targetToken.tokenId
        );
    }

    function updateTarget(
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) public {
        require(
            targetToken.tokenAddress != address(0),
            "target/parent token address should not be address(0)"
        );

        _beforeUpdateTarget(sourceToken, targetToken);

        require(
            _checkItemsExists(sourceToken),
            "source/child token not in contract"
        );
        require(
            _checkItemsExists(targetToken),
            "target/parent token token not in contract"
        );

        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            sourceToken
        );
        // maybe root token source other contract NFT, so use down code
        require(
            ERC721(rootTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller is not owner of source/child token"
        );

        _addSource(sourceToken, targetToken);

        _target[sourceToken.tokenAddress][sourceToken.tokenId] = ERC721Token(
            targetToken.tokenAddress,
            targetToken.tokenId
        );
    }

    function unlink(address to, ERC721Token memory sourceToken) public {
        // require(sourceToken.tokenAddress != address(this), "not child token");
        require(
            _checkItemsExists(sourceToken),
            "source/child token not in contract"
        );

        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            sourceToken
        );
        require(
            ERC721(rootTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller is not owner of source/child token"
        );

        (address targetTokenAddress, uint256 targetTokenId) = getTarget(
            sourceToken
        );

        bytes32 _sourceToken = keccak256(
            abi.encode(sourceToken.tokenAddress, sourceToken.tokenId)
        );
        _source[targetTokenAddress][targetTokenId].remove(_sourceToken);

        delete _target[sourceToken.tokenAddress][sourceToken.tokenId];

        ERC721(sourceToken.tokenAddress).safeTransferFrom(
            address(this),
            to,
            sourceToken.tokenId
        );
    }

    function safeMint(address to) public {
        uint256 tokenId = _lastTokenId.current();
        _lastTokenId.increment();
        _safeMint(to, tokenId);
    }

    function _beforeLink(
        address from,
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) internal virtual {}

    function _beforeUpdateTarget(
        ERC721Token memory sourceToken,
        ERC721Token memory targetToken
    ) internal virtual {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
