// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import './libraries/FullMath.sol';
import './libraries/TickMath.sol';
import '../interfaces/IKeep3r.sol';
import '../interfaces/external/IKeep3rV1.sol';
import '../interfaces/IKeep3rHelperParameters.sol';
import './peripherals/Governable.sol';
import './Keep3rHelperParameters.sol';

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

contract Keep3rHelperParameters is IKeep3rHelperParameters, Governable {
  /// @inheritdoc IKeep3rHelperParameters
  address public constant override KP3R = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;

  /// @inheritdoc IKeep3rHelperParameters
  uint256 public constant override BOOST_BASE = 10_000;

  /// @inheritdoc IKeep3rHelperParameters
  uint256 public override minBoost = 11_000;

  /// @inheritdoc IKeep3rHelperParameters
  uint256 public override maxBoost = 12_000;

  /// @inheritdoc IKeep3rHelperParameters
  uint256 public override targetBond = 200 ether;

  /// @inheritdoc IKeep3rHelperParameters
  uint256 public override workExtraGas = 50_000;

  /// @inheritdoc IKeep3rHelperParameters
  uint32 public override quoteTwapTime = 10 minutes;

  /// @inheritdoc IKeep3rHelperParameters
  uint256 public override minBaseFee = 15e9;

  /// @inheritdoc IKeep3rHelperParameters
  uint256 public override minPriorityFee = 2e9;

  /// @inheritdoc IKeep3rHelperParameters
  address public override keep3rV2;

  /// @inheritdoc IKeep3rHelperParameters
  IKeep3rHelperParameters.Kp3rWethPool public override kp3rWethPool;

  constructor(address _keep3rV2, address _governance) Governable(_governance) {
    keep3rV2 = _keep3rV2;
    _setKp3rWethPool(0x11B7a6bc0259ed6Cf9DB8F499988F9eCc7167bf5);
  }

  /// @inheritdoc IKeep3rHelperParameters
  function setKp3rWethPool(address _poolAddress) external override onlyGovernance {
    _setKp3rWethPool(_poolAddress);
    emit Kp3rWethPoolChange(kp3rWethPool.poolAddress, kp3rWethPool.isKP3RToken0);
  }

  /// @inheritdoc IKeep3rHelperParameters
  function setMinBoost(uint256 _minBoost) external override onlyGovernance {
    minBoost = _minBoost;
    emit MinBoostChange(minBoost);
  }

  /// @inheritdoc IKeep3rHelperParameters
  function setMaxBoost(uint256 _maxBoost) external override onlyGovernance {
    maxBoost = _maxBoost;
    emit MaxBoostChange(maxBoost);
  }

  /// @inheritdoc IKeep3rHelperParameters
  function setTargetBond(uint256 _targetBond) external override onlyGovernance {
    targetBond = _targetBond;
    emit TargetBondChange(targetBond);
  }

  /// @inheritdoc IKeep3rHelperParameters
  function setKeep3rV2(address _keep3rV2) external override onlyGovernance {
    keep3rV2 = _keep3rV2;
    emit Keep3rV2Change(keep3rV2);
  }

  /// @inheritdoc IKeep3rHelperParameters
  function setWorkExtraGas(uint256 _workExtraGas) external override onlyGovernance {
    workExtraGas = _workExtraGas;
    emit WorkExtraGasChange(workExtraGas);
  }

  /// @inheritdoc IKeep3rHelperParameters
  function setQuoteTwapTime(uint32 _quoteTwapTime) external override onlyGovernance {
    quoteTwapTime = _quoteTwapTime;
    emit QuoteTwapTimeChange(quoteTwapTime);
  }

  /// @inheritdoc IKeep3rHelperParameters
  function setMinBaseFee(uint256 _minBaseFee) external override onlyGovernance {
    minBaseFee = _minBaseFee;
    emit MinBaseFeeChange(minBaseFee);
  }

  /// @inheritdoc IKeep3rHelperParameters
  function setMinPriorityFee(uint256 _minPriorityFee) external override onlyGovernance {
    minPriorityFee = _minPriorityFee;
    emit MinPriorityFeeChange(minPriorityFee);
  }

  /// @notice Sets KP3R-WETH pool
  /// @param _poolAddress The address of the KP3R-WETH pool
  function _setKp3rWethPool(address _poolAddress) internal {
    bool _isKP3RToken0 = IUniswapV3Pool(_poolAddress).token0() == KP3R;
    bool _isKP3RToken1 = IUniswapV3Pool(_poolAddress).token1() == KP3R;

    if (!_isKP3RToken0 && !_isKP3RToken1) revert InvalidKp3rPool();

    kp3rWethPool = Kp3rWethPool(_poolAddress, _isKP3RToken0);
  }
}