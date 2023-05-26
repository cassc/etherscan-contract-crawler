// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRiverMenArt.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract RiverMenArt is IRiverMenArt, ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private _tokenIds;

    string public baseURI;

    mapping(uint256 => uint24) private _tokenResource;

    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        baseURI = _initBaseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function tokenResource(uint256 tokenId) public view override returns (uint24) {
        return _tokenResource[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override(IRiverMenArt, ERC721) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), uint256(_tokenResource[tokenId]).toString()));
    }

    function _awardItem(address receiver) private returns (uint256) {
        _tokenIds.increment();
        uint256 newId = _tokenIds.current();
        _safeMint(receiver, newId);
        return newId;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setBaseURI(string memory newBaseURI) public override onlyOwner {
        baseURI = newBaseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function batchMint(address[] memory receivers, uint16[] memory resourceIds) public override onlyOwner {
        require(receivers.length == resourceIds.length, "receivers length must equal resourceIds length");
        for (uint16 idx = 0; idx < resourceIds.length; ++idx) {
            uint256 newId = _awardItem(receivers[idx]);
            _tokenResource[newId] = resourceIds[idx];
            emit Mint(receivers[idx], newId);
        }
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }
        return super.isApprovedForAll(owner, operator);
    }
}