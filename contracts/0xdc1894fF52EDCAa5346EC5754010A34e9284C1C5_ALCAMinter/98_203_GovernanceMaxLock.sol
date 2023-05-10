// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract GovernanceMaxLock {
    // _MAX_GOVERNANCE_LOCK describes the maximum interval
    // a position may remained locked due to a
    // governance action
    // this value is approx 30 days worth of blocks
    // prevents double spend of voting weight
    uint256 internal constant _MAX_GOVERNANCE_LOCK = 172800;
}