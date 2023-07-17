// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

interface INA721Standard {

    // ---
    // Struct
    // ---

    // @dev NftOptions to make setup of contract a lot easier.
    struct NftOptions {
        string name;
        string symbol;
        uint16 imnotArtBps;
        uint16 royaltyBps;
        uint256 startingTokenId;
        uint256 maxInvocations;
        string contractUri;
    }
}