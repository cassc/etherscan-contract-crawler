// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { Registrar } from "../Registrar.sol";
import { Context } from "../lib/utils/Context.sol";

contract VYSupplyTracker is Context {

  uint256 private _stakeSupply;
  address private _vyTokenAddress;

  constructor(uint256 initialStakeSupply) {
    _stakeSupply = initialStakeSupply;
  }

  modifier onlyVYToken() {
    require(_msgSender() == _vyTokenAddress, "Caller must be VY token");
    _;
  }

  function getStakeSupply() public view returns (uint256) {
    return _stakeSupply;
  }

  function increaseStakeSupply(uint256 amount) external onlyVYToken {
    _stakeSupply += amount;
  }

  function decreaseStakeSupply(uint256 amount) external onlyVYToken {
    if (amount > _stakeSupply) {
        _stakeSupply = 0;
    } else {
        _stakeSupply -= amount;
    }
  }

  function _updateVYSupplyTracker(Registrar registrar) internal {
    _vyTokenAddress = registrar.getVYToken();
  }
}