//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

import {OracleLibrary} from "./libraries/OracleLibrary.sol";
import {UniswapHelpers} from "./libraries/UniswapHelpers.sol";
import {
    IUniswapOracleFundingRateController,
    IFundingRateController
} from "./interfaces/IUniswapOracleFundingRateController.sol";

contract UniswapOracleFundingRateController is IUniswapOracleFundingRateController {
    /// @inheritdoc IFundingRateController
    ERC20 public immutable underlying;
    /// @inheritdoc IFundingRateController
    ERC20 public immutable papr;
    /// @inheritdoc IFundingRateController
    uint256 public fundingPeriod;
    /// @inheritdoc IUniswapOracleFundingRateController
    address public pool;
    /// @dev the max value of target / mark, used as a guard in _multiplier
    uint256 internal immutable _targetMarkRatioMax = 3e18;
    /// @dev the min value of target / mark, used as a guard in _multiplier
    uint256 internal immutable _targetMarkRatioMin = 0.5e18;
    // single slot, write together
    uint128 internal _target;
    int56 internal _lastCumulativeTick;
    uint48 internal _lastUpdated;
    int24 internal _lastTwapTick;

    constructor(ERC20 _underlying, ERC20 _papr) {
        underlying = _underlying;
        papr = _papr;

        _setFundingPeriod(90 days);
    }

    /// @inheritdoc IFundingRateController
    function updateTarget() public override returns (uint256 nTarget) {
        if (_lastUpdated == block.timestamp) {
            return _target;
        }

        (int56 latestCumulativeTick, int24 latestTwapTick) = _latestTwapTickAndTickCumulative();
        nTarget = _newTarget(latestTwapTick, _target);

        _target = SafeCastLib.safeCastTo128(nTarget);
        // will not overflow for 8000 years
        _lastUpdated = uint48(block.timestamp);
        _lastCumulativeTick = latestCumulativeTick;
        _lastTwapTick = latestTwapTick;

        emit UpdateTarget(nTarget);
    }

    /// @inheritdoc IFundingRateController
    function newTarget() public view override returns (uint256) {
        if (_lastUpdated == block.timestamp) {
            return _target;
        }
        (, int24 latestTwapTick) = _latestTwapTickAndTickCumulative();
        return _newTarget(latestTwapTick, _target);
    }

    /// @inheritdoc IFundingRateController
    function mark() public view returns (uint256) {
        if (_lastUpdated == block.timestamp) {
            return _mark(_lastTwapTick);
        }
        (, int24 latestTwapTick) = _latestTwapTickAndTickCumulative();
        return _mark(latestTwapTick);
    }

    /// @inheritdoc IFundingRateController
    function lastUpdated() external view override returns (uint256) {
        return _lastUpdated;
    }

    /// @inheritdoc IFundingRateController
    function target() external view override returns (uint256) {
        return _target;
    }

    /// @notice initializes the controller, setting pool and target
    /// @dev assumes pool is initialized, does not check that pool tokens
    /// match papr and underlying
    /// @param _target_ the start value of target
    /// @param _pool the pool address to use
    function _init(uint256 _target_, address _pool) internal {
        if (_lastUpdated != 0) revert AlreadyInitialized();

        _setPool(_pool);

        _lastUpdated = uint48(block.timestamp);
        _target = SafeCastLib.safeCastTo128(_target_);
        _lastCumulativeTick = OracleLibrary.latestCumulativeTick(pool);
        _lastTwapTick = UniswapHelpers.poolCurrentTick(pool);

        emit UpdateTarget(_target_);
    }

    /// @notice Updates `pool`
    /// @dev reverts if new pool does not have same token0 and token1 as `pool`
    /// @dev if pool = address(0), does NOT check that tokens match papr and underlying
    function _setPool(address _pool) internal {
        address currentPool = pool;
        if (currentPool != address(0) && !UniswapHelpers.poolsHaveSameTokens(currentPool, _pool)) {
            revert PoolTokensDoNotMatch();
        }
        if (!UniswapHelpers.isUniswapPool(_pool)) revert InvalidUniswapV3Pool();

        pool = _pool;

        emit SetPool(_pool);
    }

    /// @notice Updates fundingPeriod
    /// @dev reverts if period is longer than 90 days or less than 7
    function _setFundingPeriod(uint256 _fundingPeriod) internal {
        if (_fundingPeriod < 28 days) revert FundingPeriodTooShort();
        if (_fundingPeriod > 365 days) revert FundingPeriodTooLong();

        fundingPeriod = _fundingPeriod;

        emit SetFundingPeriod(_fundingPeriod);
    }

    /// @dev internal function to allow optimized SLOADs
    function _newTarget(int24 latestTwapTick, uint256 cachedTarget) internal view returns (uint256) {
        return FixedPointMathLib.mulWadDown(cachedTarget, _multiplier(_mark(latestTwapTick), cachedTarget));
    }

    /// @dev internal function to allow optimized SLOADs
    function _mark(int24 twapTick) internal view returns (uint256) {
        return OracleLibrary.getQuoteAtTick(twapTick, 1e18, address(papr), address(underlying));
    }

    /// @dev reverts if block.timestamp - _lastUpdated == 0
    function _latestTwapTickAndTickCumulative() internal view returns (int56 tickCumulative, int24 twapTick) {
        tickCumulative = OracleLibrary.latestCumulativeTick(pool);
        twapTick = OracleLibrary.timeWeightedAverageTick(
            _lastCumulativeTick, tickCumulative, int56(uint56(block.timestamp - _lastUpdated))
        );
    }

    /// @notice The multiplier to apply to target() to get newTarget()
    /// @dev Computes the funding rate for the time since _lastUpdated
    /// 1 = 1e18, i.e.
    /// > 1e18 means positive funding rate
    /// < 1e18 means negative funding rate
    /// sub 1e18 to get percent change
    /// @return multiplier used to obtain newTarget()
    function _multiplier(uint256 _mark_, uint256 cachedTarget) internal view returns (uint256) {
        uint256 period = block.timestamp - _lastUpdated;
        uint256 periodRatio = FixedPointMathLib.divWadDown(period, fundingPeriod);
        uint256 targetMarkRatio;
        if (_mark_ == 0) {
            targetMarkRatio = _targetMarkRatioMax;
        } else {
            targetMarkRatio = FixedPointMathLib.divWadDown(cachedTarget, _mark_);
            if (targetMarkRatio > _targetMarkRatioMax) {
                targetMarkRatio = _targetMarkRatioMax;
            } else if (targetMarkRatio < _targetMarkRatioMin) {
                targetMarkRatio = _targetMarkRatioMin;
            }
        }

        // safe to cast because targetMarkRatio > 0
        return uint256(FixedPointMathLib.powWad(int256(targetMarkRatio), int256(periodRatio)));
    }
}