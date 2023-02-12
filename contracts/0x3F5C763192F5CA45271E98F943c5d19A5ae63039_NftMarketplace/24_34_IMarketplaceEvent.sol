// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "../lib/LibSignature.sol";
struct Sig {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

interface IMarketplaceEvent {
    event NewMarketplace(address indexed marketPlace);
    event BuyNowInfo(bytes32 indexed makerStructHash, address takerAddress);
    event Match(
        bytes32 indexed makerStructHash,
        bytes32 indexed takerStructHash,
        LibSignature.AuctionType auctionType,
        Sig makerSig,
        Sig takerSig,
        bool privateSale
    );
    event Match2A(
        bytes32 indexed makerStructHash,
        address indexed makerAddress,
        address indexed takerAddress,
        uint256 start,
        uint256 end,
        uint256 nonce,
        uint256 salt
    );
    event Match2B(
        bytes32 indexed makerStructHash,
        bytes[] sellerMakerOrderAssetData,
        bytes[] sellerMakerOrderAssetTypeData,
        bytes4[] sellerMakerOrderAssetClass,
        bytes[] sellerTakerOrderAssetData,
        bytes[] sellerTakerOrderAssetTypeData,
        bytes4[] sellerTakerOrderAssetClass
    );
    event Match3A(
        bytes32 indexed takerStructHash,
        address indexed makerAddress,
        address indexed takerAddress,
        uint256 start,
        uint256 end,
        uint256 nonce,
        uint256 salt
    );
    event Match3B(
        bytes32 indexed takerStructHash,
        bytes[] buyerMakerOrderAssetData,
        bytes[] buyerMakerOrderAssetTypeData,
        bytes4[] buyerMakerOrderAssetClass,
        bytes[] buyerTakerOrderAssetData,
        bytes[] buyerTakerOrderAssetTypeData,
        bytes4[] buyerTakerOrderAssetClass
    );
}