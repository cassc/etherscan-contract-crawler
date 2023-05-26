// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct EnsListing {
    uint256 priceInWei;
    uint256 nonce;
    uint256 domainNonce;
    uint256 sellerNonce;
    bytes32 domain;
    address seller;
    uint64 expires;
    uint32 fuses;
    string label;
}