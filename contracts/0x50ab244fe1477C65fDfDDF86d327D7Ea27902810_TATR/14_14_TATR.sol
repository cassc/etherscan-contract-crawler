// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title TaterDAO Land Title Contract
/// @author Will Holley <721.dev>
contract TATR is ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //////////////////////////////
    /// State
    //////////////////////////////

    // API Endpoint
    string public baseURI;

    // Token -> Metadata ID
    mapping(uint256 => string) public metadataIdByTokenId;

    // Metadata ID -> Token
    mapping(string => uint256) public tokenIdByMetadataId;

    //////////////////////////////
    /// Errors
    //////////////////////////////

    error OwnerOnly();

    //////////////////////////////
    /// Constructor
    //////////////////////////////

    /// @param baseURI_ TaterDAO API Endpoint
    constructor(string memory baseURI_) ERC721("TaterDAO Land Title", "TATR") {
        baseURI = baseURI_;

        // The ID of the first minted token will be 1. This ensures that no tokens have an ID of
        // 0 and prevents a false positive when calling `tokenByMetadataId` on burned tokens,
        // will always return 0 (after `delete tokenByMetadataId[tokenId]` is called within burn).
        _tokenIds.increment();
    }

    //////////////////////////////
    /// Getters
    //////////////////////////////

    /// @dev Overwrite default implementation in order to return metadata ids.
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId_);
        return string(abi.encodePacked(baseURI, metadataIdByTokenId[tokenId_]));
    }

    //////////////////////////////
    /// Public Functions
    //////////////////////////////

    function mint(string memory metadataId_) public returns (uint256) {
        // Get token id
        uint256 id = _tokenIds.current();

        metadataIdByTokenId[id] = metadataId_;
        tokenIdByMetadataId[metadataId_] = id;

        _safeMint(msg.sender, id);

        _tokenIds.increment();
        return id;
    }

    /// @dev Deletes token and frees mappings.
    function burn(uint256 tokenId_) public {
        if (msg.sender != ownerOf(tokenId_)) revert OwnerOnly();
        _burn(tokenId_);

        delete tokenIdByMetadataId[metadataIdByTokenId[tokenId_]];
        delete metadataIdByTokenId[tokenId_];
    }
}