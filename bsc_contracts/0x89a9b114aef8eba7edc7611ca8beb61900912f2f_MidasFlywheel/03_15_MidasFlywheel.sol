// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { MidasFlywheelCore } from "./MidasFlywheelCore.sol";
import "./IMidasFlywheel.sol";

contract MidasFlywheel is MidasFlywheelCore, IMidasFlywheel {
  bool public constant isRewardsDistributor = true;

  bool public constant isFlywheel = true;

  function flywheelPreSupplierAction(address market, address supplier) external {
    accrue(ERC20(market), supplier);
  }

  function flywheelPreBorrowerAction(address market, address borrower) external {}

  function flywheelPreTransferAction(
    address market,
    address src,
    address dst
  ) external {
    accrue(ERC20(market), src, dst);
  }

  function compAccrued(address user) external view returns (uint256) {
    return rewardsAccrued[user];
  }

  function addMarketForRewards(ERC20 strategy) external onlyOwner {
    _addStrategyForRewards(strategy);
  }

  function marketState(ERC20 strategy) external view returns (uint224, uint32) {
    return (strategyState[strategy].index, strategyState[strategy].lastUpdatedTimestamp);
  }
}