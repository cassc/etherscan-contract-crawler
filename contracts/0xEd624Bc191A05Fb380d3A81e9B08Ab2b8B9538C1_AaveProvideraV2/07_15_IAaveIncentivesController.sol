// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

interface IAaveIncentivesController {
  function REWARD_TOKEN() external view returns (address);

  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

}