// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.13;

library Shared {
    struct MetaData {
        bool whitelistOnly;
        bool hidden;
        uint24 maxSupply; // can be minted up to MAX_SUPPLY
        uint24 royaltyFriction; // used for `royaltyInfo` (ERC2981) and `seller_fee_basis_points` (Opeansea's Contract-level metadata)
        uint40 mintingBeginsFrom; // Timestamp that minting event begins
        uint152 mintingCost; // Native token (ETH, BNB, KLAY, etc)
    }
}