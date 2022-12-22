// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../interfaces/IZap.sol";

import "./ConcentratorStrategyBase.sol";

abstract contract AutoCompoundingStrategyBase is ConcentratorStrategyBase {
  using SafeERC20 for IERC20;

  function _harvest(
    address _zapper,
    address _intermediate,
    address _target,
    address[] memory _rewards,
    uint256[] memory _amounts
  ) internal returns (uint256 _harvested) {
    // 1. zap all rewards to intermediate token.
    for (uint256 i = 0; i < rewards.length; i++) {
      address _rewardToken = _rewards[i];
      uint256 _amount = _amounts[i];
      if (_rewardToken == _intermediate) {
        _harvested += _amount;
      } else if (_amount > 0) {
        IERC20(_rewardToken).safeTransfer(_zapper, _amount);
        _harvested += IZap(_zapper).zap(_rewardToken, _amount, _intermediate, 0);
      }
    }

    // 2. add liquidity to staking token.
    if (_harvested > 0) {
      if (_intermediate == address(0)) {
        _harvested = IZap(_zapper).zap{ value: _harvested }(_intermediate, _harvested, _target, 0);
      } else {
        IERC20(_intermediate).safeTransfer(_zapper, _harvested);
        _harvested = IZap(_zapper).zap(_intermediate, _harvested, _target, 0);
      }
    }
  }
}