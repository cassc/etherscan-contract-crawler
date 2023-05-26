// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct EnsOffer {
    uint256 nonce;
    uint256 bidderNonce;
    uint256 priceInWei;
    bytes32 domain;
    address bidder;
    uint64 expires;
    address resolver;
    uint32 fuses;
    string label;
}