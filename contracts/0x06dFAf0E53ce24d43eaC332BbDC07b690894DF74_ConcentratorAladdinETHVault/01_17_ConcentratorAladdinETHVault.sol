// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../ConcentratorGeneralVault.sol";
import "../interfaces/IAladdinCompounder.sol";
import "../../interfaces/ICurveETHPool.sol";
import "../../interfaces/IZap.sol";

// solhint-disable reason-string

contract ConcentratorAladdinETHVault is ConcentratorGeneralVault {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @dev The address of aladdinETH token.
  address private aladdinETH;

  /// @dev The address of underlying token for aladdinETH.
  address private aladdinETHUnderlying;

  function initialize(
    address _aladdinETH,
    address _zap,
    address _platform
  ) external initializer {
    require(_aladdinETH != address(0), "Concentrator: zero aladdinETH address");
    ConcentratorGeneralVault._initialize(_zap, _platform);

    address _aladdinETHUnderlying = IAladdinCompounder(_aladdinETH).asset();
    IERC20Upgradeable(_aladdinETHUnderlying).safeApprove(_aladdinETH, uint256(-1));

    aladdinETH = _aladdinETH;
    aladdinETHUnderlying = _aladdinETHUnderlying;
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc IConcentratorGeneralVault
  function rewardToken() public view virtual override returns (address) {
    return aladdinETH;
  }

  /********************************** Internal Functions **********************************/

  /// @inheritdoc ConcentratorGeneralVault
  function _claim(
    uint256 _amount,
    uint256 _minOut,
    address _recipient,
    address _claimAsToken
  ) internal virtual override returns (uint256) {
    address _aladdinETH = aladdinETH;
    uint256 _amountOut;
    if (_claimAsToken == _aladdinETH) {
      _amountOut = _amount;
    } else {
      _amountOut = IAladdinCompounder(_aladdinETH).redeem(_amount, address(this), address(this));
      address _aladdinETHUnderlying = aladdinETHUnderlying;
      if (_claimAsToken != _aladdinETHUnderlying) {
        address _zap = zap;
        IERC20Upgradeable(_aladdinETHUnderlying).safeTransfer(_zap, _amountOut);
        _amountOut = IZap(_zap).zap(_aladdinETHUnderlying, _amountOut, _claimAsToken, 0);
      }
    }

    require(_amountOut >= _minOut, "Concentrator: insufficient rewards");

    if (_claimAsToken == address(0)) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool _success, ) = msg.sender.call{ value: _amount }("");
      require(_success, "Concentrator: transfer ETH failed");
    } else {
      IERC20Upgradeable(_claimAsToken).safeTransfer(_recipient, _amountOut);
    }

    return _amountOut;
  }

  /// @inheritdoc ConcentratorGeneralVault
  function _harvest(uint256 _pid) internal virtual override returns (uint256) {
    address _strategy = poolInfo[_pid].strategy.strategy;
    address _zap = zap;
    uint256 _amountETH = IConcentratorStrategy(_strategy).harvest(_zap, address(0));

    uint256 _amount = IZap(_zap).zap{ value: _amountETH }(address(0), _amountETH, aladdinETHUnderlying, 0);

    return IAladdinCompounder(aladdinETH).deposit(_amount, address(this));
  }
}