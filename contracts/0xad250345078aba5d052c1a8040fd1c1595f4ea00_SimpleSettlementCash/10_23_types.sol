// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct Bid {
    // vault selling structures
    address vault;
    // Indicated how much the vault is short or long this instrument in a structure
    int256[] weights;
    // option ids
    uint256[] options;
    // id of asset
    uint8 premiumId;
    // premium paid to vault
    int256 premium;
    // expiration of bid
    uint256 expiry;
    // Number only used once
    uint256 nonce;
    // Signature recovery id
    uint8 v;
    // r portion of the ECSDA signature
    bytes32 r;
    // s portion of the ECSDA signature
    bytes32 s;
}