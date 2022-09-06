// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "../interfaces/IGuardedLaunch.sol";
import "./TwoStepOwnable.sol";
import "./Manageable.sol";

/// @title GuardedLaunch
/// @notice Implements security and risk averse functions for Silo
/// @dev This contract is meant to limit Silo functionality for Beta Release in order to minimize any damage
/// of potential critical vulnerability.
/// @custom:security-contact [email protected]
contract GuardedLaunch is IGuardedLaunch, TwoStepOwnable, Manageable {
    uint256 private constant _INFINITY = type(uint256).max;

    /// @dev Initial value for defaultMaxLiquidity is 250 quote tokens
    uint256 private constant _INITIAL_MAX_LIQUIDITY = 250 * 1e18;

    /// @dev stores max liquidity config
    MaxLiquidityLimit public maxLiquidity;

    /// @dev stores pause config
    Paused public isPaused;

    error GlobalLimitDidNotChange();
    error GlobalPauseDidNotChange();
    error MaxLiquidityDidNotChange();
    error SiloMaxLiquidityDidNotChange();
    error SiloPauseDidNotChange();

    constructor() Manageable(msg.sender) {
        maxLiquidity.globalLimit = true;

        maxLiquidity.defaultMaxLiquidity = _INITIAL_MAX_LIQUIDITY;
    }

    /// @inheritdoc IGuardedLaunch
    function setLimitedMaxLiquidity(bool _globalLimit) external onlyManager override {
        if (maxLiquidity.globalLimit == _globalLimit) revert GlobalLimitDidNotChange();

        maxLiquidity.globalLimit = _globalLimit;
        emit LimitedMaxLiquidityToggled(maxLiquidity.globalLimit);
    }

    /// @inheritdoc IGuardedLaunch
    function setDefaultSiloMaxDepositsLimit(uint256 _maxDeposits) external onlyManager override {
        if (maxLiquidity.defaultMaxLiquidity == _maxDeposits) {
            revert MaxLiquidityDidNotChange();
        }

        maxLiquidity.defaultMaxLiquidity = _maxDeposits;
        emit DefaultSiloMaxDepositsLimitUpdate(_maxDeposits);
    }

    /// @inheritdoc IGuardedLaunch
    function setSiloMaxDepositsLimit(
        address _silo,
        address _asset,
        uint256 _maxDeposits
    ) external onlyManager override {
        if (maxLiquidity.siloMaxLiquidity[_silo][_asset] == _maxDeposits) {
            revert SiloMaxLiquidityDidNotChange();
        }

        maxLiquidity.siloMaxLiquidity[_silo][_asset] = _maxDeposits;
        emit SiloMaxDepositsLimitsUpdate(_silo, _asset, _maxDeposits);
    }

    /// @inheritdoc IGuardedLaunch
    function setGlobalPause(bool _globalPause) external onlyManager override {
        if (isPaused.globalPause == _globalPause) revert GlobalPauseDidNotChange();

        isPaused.globalPause = _globalPause;
        emit GlobalPause(_globalPause);
    }

    /// @inheritdoc IGuardedLaunch
    function setSiloPause(address _silo, address _asset, bool _pauseValue) external onlyManager override {
        if (isPaused.siloPause[_silo][_asset] == _pauseValue) {
            revert SiloPauseDidNotChange();
        }

        isPaused.siloPause[_silo][_asset] = _pauseValue;
        emit SiloPause(_silo, _asset, _pauseValue);
    }

    /// @inheritdoc IGuardedLaunch
    function isSiloPaused(address _silo, address _asset) external view override returns (bool) {
        return isPaused.globalPause || isPaused.siloPause[_silo][address(0)] || isPaused.siloPause[_silo][_asset];
    }

    /// @inheritdoc IGuardedLaunch
    function getMaxSiloDepositsValue(address _silo, address _asset) external view override returns (uint256) {
        if (maxLiquidity.globalLimit) {
            uint256 maxDeposits = maxLiquidity.siloMaxLiquidity[_silo][_asset];
            if (maxDeposits != 0) {
                return maxDeposits;
            }
            return maxLiquidity.defaultMaxLiquidity;
        }
        return _INFINITY;
    }

    /// @dev Returns the address of the current owner.
    function owner() public view override(TwoStepOwnable, Manageable) virtual returns (address) {
        return TwoStepOwnable.owner();
    }
}