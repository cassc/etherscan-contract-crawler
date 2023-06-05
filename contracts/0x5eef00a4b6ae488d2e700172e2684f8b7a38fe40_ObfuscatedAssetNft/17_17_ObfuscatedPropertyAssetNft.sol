// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct ObfuscatedAsset {
    string updatedAt;
    string name;
    uint32 totalCount;
    string description;
    string idList;
    string coordinates;
    string ownerName;
    string testUrl;
    uint128 valuationUsd;
    uint128 valuationObf;
    uint128 netValueUsd;
    uint128 netValueObf;
    uint32 potentialRevenueUsd;
    uint32 actualRevenueUsd;
}

contract ObfuscatedAssetNft is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable
{
    // Libraries
    using Counters for Counters.Counter;

    // Events
    event ObfuscatedAssetTokenUpdated(uint256 tokenId);

    // State variables
    mapping(uint256 => ObfuscatedAsset) tokens;

    // Constructor
    constructor() ERC721("Obfuscated Assets", "OBFASSET") {}

    // Functions
    function safeMint(
        address to,
        uint256 tokenId,
        string memory updatedAt,
        string memory name,
        uint32 totalCount,
        string memory description,
        string memory idList,
        string memory coordinates,
        string memory ownerName,
        string memory testUrl
    ) external onlyOwner {
        _safeMint(to, tokenId);

        updateAssetDetails(
            tokenId,
            updatedAt,
            name,
            totalCount,
            description,
            idList,
            coordinates,
            ownerName,
            testUrl
        );
    }

    function tokenAtId(
        uint256 tokenId
    ) external view returns (ObfuscatedAsset memory) {
        _requireMinted(tokenId);
        ObfuscatedAsset storage obfuscated_token = tokens[tokenId];

        return obfuscated_token;
    }

    function updateAssetDetails(
        uint256 tokenId,
        string memory updatedAt,
        string memory name,
        uint32 totalCount,
        string memory description,
        string memory idList,
        string memory coordinates,
        string memory ownerName,
        string memory testUrl
    ) public onlyOwner {
        _requireMinted(tokenId);

        ObfuscatedAsset storage token = tokens[tokenId];
        token.updatedAt = updatedAt;
        token.name = name;
        token.totalCount = totalCount;
        token.description = description;
        token.idList = idList;
        token.coordinates = coordinates;
        token.ownerName = ownerName;
        token.testUrl = testUrl;

        emit ObfuscatedAssetTokenUpdated(tokenId);
    }

    function updateAssetFinancials(
        uint256 tokenId,
        string memory updatedAt,
        uint128 valuationUsd,
        uint128 valuationObf,
        uint128 netValueUsd,
        uint128 netValueObf,
        uint32 potentialRevenueUsd,
        uint32 actualRevenueUsd
    ) external onlyOwner {
        _requireMinted(tokenId);

        ObfuscatedAsset storage token = tokens[tokenId];
        token.updatedAt = updatedAt;
        token.valuationUsd = valuationUsd;
        token.valuationObf = valuationObf;
        token.netValueUsd = netValueUsd;
        token.netValueObf = netValueObf;
        token.potentialRevenueUsd = potentialRevenueUsd;
        token.actualRevenueUsd = actualRevenueUsd;

        emit ObfuscatedAssetTokenUpdated(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}