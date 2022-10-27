// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

interface IMidasFlywheel {
  function isRewardsDistributor() external returns (bool);

  function isFlywheel() external returns (bool);

  function flywheelPreSupplierAction(address market, address supplier) external;

  function flywheelPreBorrowerAction(address market, address borrower) external;

  function flywheelPreTransferAction(
    address market,
    address src,
    address dst
  ) external;

  function compAccrued(address user) external view returns (uint256);

  function addMarketForRewards(address strategy) external;

  function marketState(address strategy) external view returns (uint224 index, uint32 lastUpdatedTimestamp);
}