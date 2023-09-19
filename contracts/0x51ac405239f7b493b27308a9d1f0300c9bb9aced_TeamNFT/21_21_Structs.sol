// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct TeamNFTData {
    uint64 sport;
    uint64 series;
    bytes32 seriesName;
    bytes32 cityName;
    bytes32 teamName;
    bytes32 color1;
    bytes32 color2;
}

struct SeriesData {
    string seriesName;
    uint128 numberOfTeams;
    uint128 nftsPerTeam;
}

/// @dev Datatype for returning owners of a tokenId with balances.
struct OwnersBalances {
    address account;
    uint256 balance;
}