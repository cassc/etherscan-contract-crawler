pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
 *
 * This code is a part of the House of Panda project.
 *
 */

struct ProjectInfo {
    uint32 id;
    string title;
    address creator;
    uint16 typeId;
    uint256 price;
    bool authorizedOnly; // whether this should be created by authorization or not.
    bytes1 status; // 0 not active, 1 active, 2 market non availability, 3 closed, 4 paused.
    uint16 term; // term in months
    uint128 supplyLimit;
    uint256 apy; // regular APY
    uint256 stakedApy; // staked APY
    uint64 startTime; // start time where user can start mint/stake.
    uint64 endTime; // end time where user can no longer mint/stake, only unstake and collect rewards.
}