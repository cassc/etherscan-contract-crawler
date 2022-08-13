// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.7.5;
pragma abicoder v2;

import { StakedMultiVestingRewards, IERC20 } from "@BootNodeDev/powertrade-stake-contracts/contracts/stake/StakedMultiVestingRewards.sol";

/**
 * @title Stake
 * @dev Contract to stake a token, tokenize the position and get rewards in multiple assets with optional vesting support
 **/
contract Stake is StakedMultiVestingRewards {
  constructor(
    IERC20 stakedToken,
    uint256 cooldownSeconds,
    uint256 unstakeWindow,
    address rewardsVault,
    address emissionManager,
    address rewardLocker,
    string memory name,
    string memory symbol,
    uint8 decimals
  )
    StakedMultiVestingRewards(
      stakedToken,
      cooldownSeconds,
      unstakeWindow,
      rewardsVault,
      emissionManager,
      rewardLocker,
      name,
      symbol,
      decimals
    )
  {
    // solhint-disable-previous-line no-empty-blocks
  }
}