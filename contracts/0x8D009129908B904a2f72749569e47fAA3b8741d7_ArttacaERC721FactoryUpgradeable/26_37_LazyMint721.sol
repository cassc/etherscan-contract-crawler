// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (lib/Marketplace.sol)

pragma solidity ^0.8.4;

import "./Ownership.sol";

/**
 * @title Arttaca Marketplace library.
 */
library LazyMint721 {
    struct TokenData {
        uint id;
        string URI;
        Ownership.Royalties royalties;
    }

    struct MintData {
        address to;
        uint expTimestamp;
        bytes signature;
    }

    struct SaleData {
        address lister;
        uint price;
        uint listingExpTimestamp;
        uint nodeExpTimestamp;
        bytes listingSignature;
        bytes nodeSignature;
    }

    bytes32 public constant MINT_TYPEHASH = keccak256("Minting(address collectionAddress,uint id,string tokenURI,Split[] splits,uint96 percentage,uint expTimestamp)Split(address account,uint96 shares)");

    function hashMint(address collectionAddress, TokenData memory _tokenData, MintData memory _mintData) internal pure returns (bytes32) {
        bytes32[] memory splitBytes = new bytes32[](_tokenData.royalties.splits.length);

        for (uint i = 0; i < _tokenData.royalties.splits.length; ++i) {
            splitBytes[i] = Ownership.hash(_tokenData.royalties.splits[i]);
        }

        return keccak256(
            abi.encode(
                MINT_TYPEHASH,
                collectionAddress,
                _tokenData.id,
                keccak256(bytes(_tokenData.URI)),
                keccak256(abi.encodePacked(splitBytes)),
                _tokenData.royalties.percentage,
                _mintData.expTimestamp
            )
        );
    }

    bytes32 public constant LISTING_TYPEHASH = keccak256("Listing(address collectionAddress,uint id,uint price,uint expTimestamp)");

    function hashListing(address collectionAddress, TokenData memory _tokenData, SaleData memory _saleData, bool isNode) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                LISTING_TYPEHASH,
                collectionAddress,
                _tokenData.id,
                _saleData.price,
                isNode ? _saleData.nodeExpTimestamp : _saleData.listingExpTimestamp
            )
        );
    }
}