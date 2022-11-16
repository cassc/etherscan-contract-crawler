// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConvexCVXRewardPool {
  function balanceOf(address account) external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function withdraw(uint256 _amount, bool claim) external;

  function withdrawAll(bool claim) external;

  function stake(uint256 _amount) external;

  function stakeAll() external;

  function stakeFor(address _for, uint256 _amount) external;

  function getReward(
    address _account,
    bool _claimExtras,
    bool _stake
  ) external;

  function getReward(bool _stake) external;
}