// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./CBRNFTDefault.sol";

/**
 * @title CollectionV2
 * @notice This NFT collection contract for user to create the own ERC721 collection
 * @dev Upgradable NFT contract to create  collection
 */

contract CollectionV2 is ReentrancyGuard, Ownable, Pausable, CBRNFTDefault {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory name,
        string memory symbol,
        string memory _contractURI,
        string memory tokenURIPrefix,
        address _admin
    ) CBRNFTDefault(name, symbol, _contractURI, tokenURIPrefix, _admin) {
        _tokenIdCounter.increment();
        transferOwnership(_admin);
    }

    function safeMint(
        address to,
        string memory tokenURI,
        address creator,
        uint256 value
    ) public override returns (uint256) {
        uint256 _tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        CBRNFTDefault.safeMint(to, _tokenId, tokenURI, creator, value);
        return _tokenId;
    }
}