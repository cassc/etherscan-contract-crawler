// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./AbstractStakeable.sol";
import "../libs/math/FixedPoint.sol";
import "../libs/ERC20Fixed.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract AbstractERC20Stakeable is
  ERC20Upgradeable,
  AbstractStakeable
{
  using FixedPoint for uint256;
  using FixedPoint for int256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using ERC20Fixed for ERC20Upgradeable;
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function __AbstractERC20Stakeable_init() internal onlyInitializing {
    __AbstractStakeable_init();
  }

  // internal functions

  function _stake(
    address sender,
    address staker,
    uint256 amount
  ) internal override {
    _update(staker, amount.toInt256());
    if (sender != address(this)) {
      ERC20Upgradeable(this).transferFromFixed(sender, address(this), amount);
    }
    emit StakeEvent(sender, staker, amount);
  }

  function _unstake(address staker, uint256 amount) internal override {
    _require(_stakedByStaker[staker] >= amount, Errors.INVALID_AMOUNT);
    _update(staker, -amount.toInt256());
    ERC20Upgradeable(this).transferFixed(staker, amount);
    emit UnstakeEvent(staker, amount);
  }
}