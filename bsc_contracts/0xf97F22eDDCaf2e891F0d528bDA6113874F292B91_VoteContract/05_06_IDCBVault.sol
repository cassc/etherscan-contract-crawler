// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDCBVault {
  function deposit(uint256 _pid, uint256 _amount) external;

  function withdrawAll(uint256 _pid) external;

  function harvestAll() external;

  function setCallFee(uint256 _callFee) external;

  function pause() external;

  function unpause() external;

  function transferToken(address _addr, uint256 _amount) external returns (bool);

  function withdraw(uint256 _pid, uint256 _shares) external;

  function harvest(uint256 _pid) external;

  function callFee() external view returns (uint256);

  function masterchef() external view returns (address);

  function owner() external view returns (address);

  function paused() external view returns (bool);

  function pools(uint256) external view returns (uint256 totalShares, uint256 lastHarvestedTime);

  function users(uint256, address)
    external
    view
    returns (
      uint256 shares,
      uint256 lastDepositedTime,
      uint256 totalInvested,
      uint256 totalClaimed
    );

  function calculateTotalPendingRewards(uint256 _pid) external view returns (uint256);

  function calculateHarvestDcbRewards(uint256 _pid) external view returns (uint256);

  function getRewardOfUser(address _user, uint256 _pid) external view returns (uint256);

  function getPricePerFullShare(uint256 _pid) external view returns (uint256);

  function canUnstake(address _user, uint256 _pid) external view returns (bool);

  function available(uint256 _pid) external view returns (uint256);

  function balanceOf(uint256 _pid) external view returns (uint256);
}