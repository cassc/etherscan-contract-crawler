// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @param receiver Custom royalty recipient address
/// @param royaltyBps Royalty in basis points
struct CustomRoyalty {
    address receiver;
    uint16 royaltyBps;
}

/// @param fanRoyalty Fan token royalty in basis points
/// @param brandRoyalty Brand token royalty in basis points
struct RoyaltySchedule {
    uint16 fanRoyalty;
    uint16 brandRoyalty;
}