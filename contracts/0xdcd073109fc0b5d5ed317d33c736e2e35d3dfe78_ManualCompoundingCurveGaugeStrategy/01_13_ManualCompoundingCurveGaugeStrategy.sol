// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../interfaces/ICurveGauge.sol";
import "../../interfaces/ICurveTokenMinter.sol";
import "../../interfaces/IZap.sol";

import "./ManualCompoundingStrategyBase.sol";

// solhint-disable no-empty-blocks
// solhint-disable reason-string

contract ManualCompoundingCurveGaugeStrategy is ManualCompoundingStrategyBase {
  using SafeERC20 for IERC20;

  /// @inheritdoc IConcentratorStrategy
  // solhint-disable const-name-snakecase
  string public constant override name = "ManualCompoundingCurveGauge";

  /// @dev The address of CRV token.
  address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

  /// @dev The address of CRV minter.
  address private constant MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

  /// @notice The address of staking token.
  address public token;

  /// @notice The address of Curve gauge contract.
  address public gauge;

  function initialize(
    address _operator,
    address _token,
    address _gauge,
    address[] memory _rewards
  ) external initializer {
    ConcentratorStrategyBase._initialize(_operator, _rewards);

    IERC20(_token).safeApprove(_gauge, uint256(-1));

    token = _token;
    gauge = _gauge;
  }

  /// @inheritdoc IConcentratorStrategy
  function deposit(address, uint256 _amount) external override onlyOperator {
    if (_amount > 0) {
      ICurveGauge(gauge).deposit(_amount);
    }
  }

  /// @inheritdoc IConcentratorStrategy
  function withdraw(address _recipient, uint256 _amount) external override onlyOperator {
    if (_amount > 0) {
      ICurveGauge(gauge).withdraw(_amount);
      IERC20(token).safeTransfer(_recipient, _amount);
    }
  }

  /// @inheritdoc IConcentratorStrategy
  function harvest(address _zapper, address _intermediate) external override onlyOperator returns (uint256 _amount) {
    // 1. claim rewards from Convex rewards contract.
    address[] memory _rewards = rewards;
    uint256[] memory _amounts = new uint256[](rewards.length);
    for (uint256 i = 0; i < rewards.length; i++) {
      _amounts[i] = IERC20(_rewards[i]).balanceOf(address(this));
    }
    address _gauge = gauge;
    ICurveTokenMinter(MINTER).mint(_gauge);
    // some gauge has no extra rewards
    try ICurveGauge(_gauge).claim_rewards() {} catch {}
    for (uint256 i = 0; i < rewards.length; i++) {
      _amounts[i] = IERC20(_rewards[i]).balanceOf(address(this)) - _amounts[i];
    }

    // 2. zap to intermediate token and transfer to caller.
    _amount = _harvest(_zapper, _intermediate, _rewards, _amounts);
  }
}