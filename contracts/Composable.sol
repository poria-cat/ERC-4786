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

    struct TargetToken {
        address tokenAddress;
        uint256 tokenId;
    }

    // source: starting node, child node
    // target: ending node, parent node

    //target/parent(one to one): ((source/child token address + id) -> (target/parent token address  + target/parent id))
    mapping(address => mapping(uint256 => TargetToken)) _target;
    // source/child(one to many): (target/parent token address + id => Set(keccak256(abi.encode(target/parent tokenaddress , target/parent id))))
    mapping(address => mapping(uint256 => EnumerableSet.Bytes32Set)) _source;

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721(_tokenName, _tokenSymbol)
    {}

    function _addSource(
        address sourceTokenAddress,
        uint256 sourceTokenId,
        address targetTokenAddress,
        uint256 targetTokenId
    ) private {
        // (address targetTokenAddress, uint256 targetTokenId) = getTarget(
        //     sourceTokenAddress,
        //     sourceTokenId
        // );
        bytes32 sourceToken = keccak256(
            abi.encode(sourceTokenAddress, sourceTokenId)
        );
        if (targetTokenAddress != address(0)) {
            _source[targetTokenAddress][targetTokenId].remove(sourceToken);
        }
        _source[targetTokenAddress][targetTokenId].add(sourceToken);
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

        (address targetTokenAddress, ) = getTarget(tokenAddress, tokenId);

        // may be a root token, should check have source/child token or not
        if (targetTokenAddress == address(0)) {
            // if token have no source/child token, it not in this contract(and it also not a root token)
            return _source[tokenAddress][tokenId].length() > 0;
        }

        // check whether root token in contract
        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            tokenAddress,
            tokenId
        );

        if (rootTokenAddress == address(this)) {
            return _exists(rootTokenId);
        } else {
            // root token is not source this contract, so check it have source/child or not
            return _source[rootTokenAddress][rootTokenId].length() > 0;
        }
    }

    function findRootToken(address sourceTokenAddress, uint256 sourceTokenId)
        public
        view
        returns (address rootTokenAddress, uint256 rootTokenId)
    {
        (address targetTokenAddress, uint256 targetTokenId) = getTarget(
            sourceTokenAddress,
            sourceTokenId
        );

        while (
            !(targetTokenAddress == address(0) ||
                targetTokenAddress == address(this))
        ) {
            (targetTokenAddress, targetTokenId) = getTarget(
                targetTokenAddress,
                targetTokenId
            );
        }
        return (targetTokenAddress, targetTokenId);
    }

    function getTarget(address sourceTokenAddress, uint256 sourceTokenId)
        public
        view
        returns (address tokenAddress, uint256 tokenId)
    {
        TargetToken memory p = _target[sourceTokenAddress][sourceTokenId];
        tokenAddress = p.tokenAddress;
        tokenId = p.tokenId;
    }

    function link(
        address sourceTokenAddress,
        uint256 sourceTokenId,
        address targetTokenAddress,
        uint256 targetTokenId
    ) public {
        require(
            targetTokenAddress != address(0),
            "target/parent token address should not be address(0)"
        );

        _beforeLink(
            msg.sender,
            sourceTokenAddress,
            sourceTokenId,
            targetTokenAddress,
            targetTokenId
        );
        // To prevent malicious use, it is prohibited to associate NFTs that are not in the contract
        require(
            _checkItemsExists(targetTokenAddress, targetTokenId),
            "target/parent token not exist"
        );
        require(
            _target[sourceTokenAddress][sourceTokenId].tokenAddress ==
                address(0),
            "source/child token has already been received"
        );

        ERC721(sourceTokenAddress).transferFrom(
            msg.sender,
            address(this),
            sourceTokenId
        );

        _addSource(
            sourceTokenAddress,
            sourceTokenId,
            targetTokenAddress,
            targetTokenId
        );

        _target[sourceTokenAddress][sourceTokenId] = TargetToken(
            targetTokenAddress,
            targetTokenId
        );
    }

    function updateTarget(
        address sourceTokenAddress,
        uint256 sourceTokenId,
        address targetTokenAddress,
        uint256 targetTokenId
    ) public {
        require(
            targetTokenAddress != address(0),
            "target/parent token address should not be address(0)"
        );

        _beforeUpdateTarget(
            sourceTokenAddress,
            sourceTokenId,
            targetTokenAddress,
            targetTokenId
        );

        require(
            _checkItemsExists(sourceTokenAddress, sourceTokenId),
            "source/child token not in contract"
        );
        require(
            _checkItemsExists(targetTokenAddress, targetTokenId),
            "target/parent token token not in contract"
        );

        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            sourceTokenAddress,
            sourceTokenId
        );
        // maybe root token source other contract NFT, so use down code
        require(
            ERC721(rootTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller is not owner of source/child token"
        );

        _addSource(
            sourceTokenAddress,
            sourceTokenId,
            targetTokenAddress,
            targetTokenId
        );

        _target[sourceTokenAddress][sourceTokenId] = TargetToken(
            targetTokenAddress,
            targetTokenId
        );
    }

    function unlink(
        address to,
        address sourceTokenAddress,
        uint256 sourceTokenId
    ) public {
        // require(sourceTokenAddress != address(this), "not child token");
        require(
            _checkItemsExists(sourceTokenAddress, sourceTokenId),
            "source/child token not in contract"
        );

        (address rootTokenAddress, uint256 rootTokenId) = findRootToken(
            sourceTokenAddress,
            sourceTokenId
        );
        require(
            ERC721(rootTokenAddress).ownerOf(rootTokenId) == msg.sender,
            "caller is not owner of source/child token"
        );

        (address targetTokenAddress, uint256 targetTokenId) = getTarget(
            sourceTokenAddress,
            sourceTokenId
        );

        bytes32 sourceToken = keccak256(
            abi.encode(sourceTokenAddress, sourceTokenId)
        );
        _source[targetTokenAddress][targetTokenId].remove(sourceToken);

        delete _target[sourceTokenAddress][sourceTokenId];

        ERC721(sourceTokenAddress).safeTransferFrom(
            address(this),
            to,
            sourceTokenId
        );
    }

    function safeMint(address to) public {
        uint256 tokenId = _lastTokenId.current();
        _lastTokenId.increment();
        _safeMint(to, tokenId);
    }

    function _beforeLink(
        address from,
        address sourceTokenAddress,
        uint256 sourceTokenId,
        address targetTokenAddress,
        uint256 targetTokenId
    ) internal virtual {}

    function _beforeUpdateTarget(
        address sourceTokenAddress,
        uint256 sourceTokenId,
        address targetTokenAddress,
        uint256 targetTokenId
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
