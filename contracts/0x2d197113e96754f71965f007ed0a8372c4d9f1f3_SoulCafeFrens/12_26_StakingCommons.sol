// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

struct StakeRequest {
    uint256 trackId;
    uint256[] ids;
    uint256[] amounts;   
}

enum StakeAction {
    Stake,
    Unstake,
    Collect
}

enum TrackType {
    ERC20,
    ERC1155,
    ERC721
}