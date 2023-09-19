// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*
 * Nifty Island token ids are a concatenation of:
 * creator: address of the token creator (160 bits)
 * nft_id: a partial nft id, up to 2^72 - 1. (72 bits)
 * supply: a supply cap for the token, up to 2^24 - 1. (24 bits)
 */

library TokenIdentifier {
    uint8 constant NFT_PARTIAL_ID_BITS = 72;
    uint8 constant SUPPLY_BITS = 24;

    uint256 constant SUPPLY_MASK = (uint256(1) << SUPPLY_BITS) - 1;

    function tokenMaxSupply(uint256 _id) internal pure returns (uint256) {
        return _id & SUPPLY_MASK;
    }

    function tokenCreator(uint256 _id) internal pure returns (address) {
        return address(uint160(_id >> (NFT_PARTIAL_ID_BITS + SUPPLY_BITS)));
    }
}