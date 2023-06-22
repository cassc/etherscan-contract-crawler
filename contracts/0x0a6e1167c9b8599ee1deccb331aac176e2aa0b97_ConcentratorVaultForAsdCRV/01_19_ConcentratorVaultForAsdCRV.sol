// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "./interfaces/IAladdinSdCRVExtension.sol";
import "../ConcentratorGeneralVault.sol";
import "../interfaces/IAladdinCompounder.sol";
import "../../interfaces/ICurveETHPool.sol";
import "../../interfaces/IZap.sol";

// solhint-disable reason-string

contract ConcentratorVaultForAsdCRV is ConcentratorGeneralVault {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // The address of CRV token.
  address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

  /// @dev The address of AladdinSdCRV token.
  address private asdCRV;

  function initialize(
    address _asdCRV,
    address _zap,
    address _platform
  ) external initializer {
    require(_asdCRV != address(0), "Concentrator: zero AladdinSdCRV address");
    ConcentratorGeneralVault._initialize(_zap, _platform);

    IERC20Upgradeable(CRV).safeApprove(_asdCRV, uint256(-1));

    asdCRV = _asdCRV;
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc IConcentratorGeneralVault
  function rewardToken() public view virtual override returns (address) {
    return asdCRV;
  }

  /********************************** Internal Functions **********************************/

  /// @inheritdoc ConcentratorGeneralVault
  function _claim(
    uint256 _amount,
    uint256,
    address _recipient,
    address _claimAsToken
  ) internal virtual override returns (uint256) {
    address _asdCRV = asdCRV;
    require(_claimAsToken == _asdCRV, "only claim as asdCRV");

    IERC20Upgradeable(_claimAsToken).safeTransfer(_recipient, _amount);

    return _amount;
  }

  /// @inheritdoc ConcentratorGeneralVault
  function _harvest(uint256 _pid) internal virtual override returns (uint256) {
    address _strategy = poolInfo[_pid].strategy.strategy;
    uint256 _amountCRV = IConcentratorStrategy(_strategy).harvest(zap, CRV);

    return IAladdinSdCRVExtension(asdCRV).depositWithCRV(_amountCRV, address(this), 0);
  }
}