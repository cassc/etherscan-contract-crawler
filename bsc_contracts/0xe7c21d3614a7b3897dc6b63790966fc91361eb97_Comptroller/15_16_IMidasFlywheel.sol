// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import { ERC20 } from "solmate/tokens/ERC20.sol";

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

  function addMarketForRewards(ERC20 strategy) external;

  function marketState(ERC20 strategy) external view returns (uint224 index, uint32 lastUpdatedTimestamp);
}