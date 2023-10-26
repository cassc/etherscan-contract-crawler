// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleRecord} from "./IOracle.sol";

interface IReturnsAggregatorWrite {
    /// @notice Takes the record from the oracle, aggregates net returns accordingly and forwards them to
    /// the staking contract.
    function processReturns(uint256 rewardAmount, uint256 principalAmount, bool shouldIncludeELRewards) external;
}