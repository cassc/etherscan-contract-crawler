// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { Registrar } from "../Registrar.sol";
import { Context } from "../lib/utils/Context.sol";

contract VYRevenueCycleCirculationTracker is Context {

  uint256 private _revenueCycleCirculation;
  address private _vyTokenAddress;

  constructor(uint256 initialCirculation) {
    _revenueCycleCirculation = initialCirculation;
  }

  modifier onlyVYToken() {
    require(_msgSender() == _vyTokenAddress, "Caller must be VYToken");
    _;
  }

  function increaseRevenueCycleCirculation(uint256 amount) external onlyVYToken {
    _revenueCycleCirculation += amount;
  }

  function decreaseRevenueCycleCirculation(uint256 amount) external onlyVYToken {
    if (amount > _revenueCycleCirculation) {
        _revenueCycleCirculation = 0;
    } else {
        _revenueCycleCirculation -= amount;
    }
  }

  function _updateVYCirculationHelper(Registrar registrar) internal {
    _vyTokenAddress = registrar.getVYToken();
  }

  function _getRevenueCycleCirculation() internal view returns (uint256) {
    return _revenueCycleCirculation;
  }
}