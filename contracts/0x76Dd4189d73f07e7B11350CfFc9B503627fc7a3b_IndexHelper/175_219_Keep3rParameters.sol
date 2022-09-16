// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "../../interfaces/IKeep3rHelper.sol";
import "../../interfaces/peripherals/IKeep3rParameters.sol";
import "./Keep3rAccountance.sol";
import "./Keep3rRoles.sol";

abstract contract Keep3rParameters is IKeep3rParameters, Keep3rAccountance, Keep3rRoles {
    /// @inheritdoc IKeep3rParameters
    address public override keep3rV1;

    /// @inheritdoc IKeep3rParameters
    address public override keep3rV1Proxy;

    /// @inheritdoc IKeep3rParameters
    address public override keep3rHelper;

    /// @inheritdoc IKeep3rParameters
    address public override kp3rWethPool;

    /// @inheritdoc IKeep3rParameters
    uint256 public override bondTime = 3 days;

    /// @inheritdoc IKeep3rParameters
    uint256 public override unbondTime = 14 days;

    /// @inheritdoc IKeep3rParameters
    uint256 public override liquidityMinimum = 3 ether;

    /// @inheritdoc IKeep3rParameters
    uint256 public override rewardPeriodTime = 5 days;

    /// @inheritdoc IKeep3rParameters
    uint256 public override inflationPeriod = 34 days;

    /// @inheritdoc IKeep3rParameters
    uint256 public override fee = 30;

    /// @inheritdoc IKeep3rParameters
    uint256 public constant override BASE = 10000;

    /// @inheritdoc IKeep3rParameters
    uint256 public constant override MIN_REWARD_PERIOD_TIME = 1 days;

    constructor(
        address _keep3rHelper,
        address _keep3rV1,
        address _keep3rV1Proxy,
        address _kp3rWethPool
    ) {
        keep3rHelper = _keep3rHelper;
        keep3rV1 = _keep3rV1;
        keep3rV1Proxy = _keep3rV1Proxy;
        kp3rWethPool = _kp3rWethPool;
        _liquidityPool[kp3rWethPool] = kp3rWethPool;
        _isKP3RToken0[_kp3rWethPool] = IKeep3rHelper(keep3rHelper).isKP3RToken0(kp3rWethPool);
    }

    /// @inheritdoc IKeep3rParameters
    function setKeep3rHelper(address _keep3rHelper) external override onlyGovernance {
        if (_keep3rHelper == address(0)) revert ZeroAddress();
        keep3rHelper = _keep3rHelper;
        emit Keep3rHelperChange(_keep3rHelper);
    }

    /// @inheritdoc IKeep3rParameters
    function setKeep3rV1(address _keep3rV1) external override onlyGovernance {
        if (_keep3rV1 == address(0)) revert ZeroAddress();
        keep3rV1 = _keep3rV1;
        emit Keep3rV1Change(_keep3rV1);
    }

    /// @inheritdoc IKeep3rParameters
    function setKeep3rV1Proxy(address _keep3rV1Proxy) external override onlyGovernance {
        if (_keep3rV1Proxy == address(0)) revert ZeroAddress();
        keep3rV1Proxy = _keep3rV1Proxy;
        emit Keep3rV1ProxyChange(_keep3rV1Proxy);
    }

    /// @inheritdoc IKeep3rParameters
    function setKp3rWethPool(address _kp3rWethPool) external override onlyGovernance {
        if (_kp3rWethPool == address(0)) revert ZeroAddress();
        kp3rWethPool = _kp3rWethPool;
        _liquidityPool[kp3rWethPool] = kp3rWethPool;
        _isKP3RToken0[_kp3rWethPool] = IKeep3rHelper(keep3rHelper).isKP3RToken0(_kp3rWethPool);
        emit Kp3rWethPoolChange(_kp3rWethPool);
    }

    /// @inheritdoc IKeep3rParameters
    function setBondTime(uint256 _bondTime) external override onlyGovernance {
        bondTime = _bondTime;
        emit BondTimeChange(_bondTime);
    }

    /// @inheritdoc IKeep3rParameters
    function setUnbondTime(uint256 _unbondTime) external override onlyGovernance {
        unbondTime = _unbondTime;
        emit UnbondTimeChange(_unbondTime);
    }

    /// @inheritdoc IKeep3rParameters
    function setLiquidityMinimum(uint256 _liquidityMinimum) external override onlyGovernance {
        liquidityMinimum = _liquidityMinimum;
        emit LiquidityMinimumChange(_liquidityMinimum);
    }

    /// @inheritdoc IKeep3rParameters
    function setRewardPeriodTime(uint256 _rewardPeriodTime) external override onlyGovernance {
        if (_rewardPeriodTime < MIN_REWARD_PERIOD_TIME) revert MinRewardPeriod();
        rewardPeriodTime = _rewardPeriodTime;
        emit RewardPeriodTimeChange(_rewardPeriodTime);
    }

    /// @inheritdoc IKeep3rParameters
    function setInflationPeriod(uint256 _inflationPeriod) external override onlyGovernance {
        inflationPeriod = _inflationPeriod;
        emit InflationPeriodChange(_inflationPeriod);
    }

    /// @inheritdoc IKeep3rParameters
    function setFee(uint256 _fee) external override onlyGovernance {
        fee = _fee;
        emit FeeChange(_fee);
    }
}