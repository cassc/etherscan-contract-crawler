// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

import './IStaking.sol';

contract IStakingAggregator {
  error StakingInvalidAggregatorAddress();
}

struct StakingInstanceData {
  address addr;
  StakingData data;
}