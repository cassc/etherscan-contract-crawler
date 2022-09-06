// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "./core_libraries/Tick.sol";
import "./interfaces/IMarginEngine.sol";
import "./interfaces/rate_oracles/IRateOracle.sol";
import "./interfaces/fcms/IFCM.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "./core_libraries/FixedAndVariableMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./core_libraries/SafeTransferLib.sol";
import "./storage/MarginEngineStorage.sol";
import "./utils/SafeCastUni.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/SqrtPriceMath.sol";

contract MarginEngine is
    MarginEngineStorage,
    IMarginEngine,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using PRBMathSD59x18 for int256;
    using PRBMathUD60x18 for uint256;

    using SafeCastUni for uint256;
    using SafeCastUni for int256;
    using Tick for mapping(int24 => Tick.Info);

    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    using SafeTransferLib for IERC20Minimal;

    /// @dev Seconds in a year
    int256 public constant SECONDS_IN_YEAR = 31536000e18;

    uint256 public constant ONE_UINT = 1e18;
    int256 public constant ONE = 1e18;

    uint256 public constant WORST_CASE_FIXED_RATE_WAD = 15e16; // 0.15 in WAD = 15%
    uint256 public constant MAX_LOOKBACK_WINDOW_IN_SECONDS = 315360000; // ten years
    uint256 public constant MIN_LOOKBACK_WINDOW_IN_SECONDS = 3600; // one hour
    uint256 public constant MAX_CACHE_MAX_AGE_IN_SECONDS = 1209600; // two weeks
    uint256 public constant MAX_LIQUIDATOR_REWARD_WAD = 3e17; // 30%

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    function setPausability(bool state) external onlyVAMM {
        paused = state;
        _fcm.setPausability(state);
    }

    /// @dev In the litepaper the timeFactor is exp(-beta*(t-s)/t_max) where t is the maturity timestamp, and t_max is the max number of seconds for the IRS AMM duration, s is the current timestamp and beta is a diffusion process parameter set via calibration
    function computeTimeFactor() internal view returns (int256 timeFactorWad) {
        uint256 currentTimestampWad = Time.blockTimestampScaled();
        require(currentTimestampWad <= _termEndTimestampWad, "CT<ET");

        require(marginCalculatorParameters.betaWad != 0, "B0");

        timeFactorWad = (
            (int256(_termEndTimestampWad) - int256(currentTimestampWad))
                .div(marginCalculatorParameters.tMaxWad)
                .mul(-marginCalculatorParameters.betaWad)
        ).exp();
    }

    /// @notice Calculates an APY Upper or Lower Bound of a given underlying pool (e.g. Aave v2 USDC Lending Pool)
    /// @param historicalApyWad Geometric Mean Time Weighted Average APY (TWAPPY) of the underlying pool (e.g. Aave v2 USDC Lending Pool)
    /// @param isUpper isUpper = true ==> calculating the APY Upper Bound, otherwise APY Lower Bound
    /// @return apyBoundWad APY Upper or Lower Bound of a given underlying pool (e.g. Aave v2 USDC Lending Pool)
    function computeApyBound(uint256 historicalApyWad, bool isUpper)
        internal
        view
        returns (uint256 apyBoundWad)
    {
        int256 timeFactorWad = computeTimeFactor();

        int256 kWad = (marginCalculatorParameters.alphaWad << 2).div(
            marginCalculatorParameters.sigmaSquaredWad
        );

        int256 lambdaWad = (marginCalculatorParameters.betaWad << 2)
            .mul(timeFactorWad)
            .mul(int256(historicalApyWad))
            .div(marginCalculatorParameters.sigmaSquaredWad)
            .div(ONE - timeFactorWad);

        int256 criticalValueWad = (((lambdaWad << 1) + kWad) << 1).sqrt().mul(
            (isUpper)
                ? marginCalculatorParameters.xiUpperWad
                : marginCalculatorParameters.xiLowerWad
        );

        if (!isUpper) {
            criticalValueWad = -criticalValueWad;
        }

        int256 apyBoundIntWad = marginCalculatorParameters
            .sigmaSquaredWad
            .mul(ONE - timeFactorWad)
            .div(marginCalculatorParameters.betaWad << 2)
            .mul(kWad + lambdaWad + criticalValueWad);

        apyBoundWad = apyBoundIntWad < 0 ? 0 : uint256(apyBoundIntWad);
    }

    /// @notice Calculates the Worst Case Variable Factor At Maturity
    /// @param isFT isFT => we are dealing with a Fixed Taker (short) IRS position, otherwise it is a Variable Taker (long) IRS position
    /// @param isLM isLM => we are computing a Liquidation Margin otherwise computing an Initial Margin
    /// @param historicalApyWad Historical Average APY of the underlying pool (e.g. Aave v2 USDC Lending Pool)
    /// @return variableFactorWad The Worst Case Variable Factor At Maturity = APY Bound * accrualFactor(timeInYearsFromStartUntilMaturity) where APY Bound = APY Upper Bound for Fixed Takers and APY Lower Bound for Variable Takers (18 decimals)
    function worstCaseVariableFactorAtMaturity(
        bool isFT,
        bool isLM,
        uint256 historicalApyWad
    ) internal view returns (uint256 variableFactorWad) {
        variableFactorWad = computeApyBound(historicalApyWad, isFT).mul(
            FixedAndVariableMath.accrualFact(
                _termEndTimestampWad - _termStartTimestampWad
            )
        );

        if (!isLM) {
            variableFactorWad = variableFactorWad.mul(
                isFT
                    ? marginCalculatorParameters.apyUpperMultiplierWad
                    : marginCalculatorParameters.apyLowerMultiplierWad
            );
        }
    }

    /// @notice calculates the absolute fixed token delta unbalanced resulting from a simulated counterfactual unwind necessary to determine the minimum margin requirement of a trader
    /// @dev simulation of a swap without the need to involve the swap function
    /// @param variableTokenDeltaAbsolute absolute value of the variableTokenDelta for which the unwind is simulated
    /// @param sqrtRatioCurrX96 sqrtRatio necessary to calculate the starting fixed rate which is used to calculate the counterfactual unwind fixed rate
    /// @param startingFixedRateMultiplierWad the multiplier (lambda from the litepaper - minimum margin requirement equation) that is multiplied by the starting fixed rate to determine the deviation applied to the starting fixed rate (in Wad)
    /// @param fixedRateDeviationMinWad The minimum value the variable D (from the litepaper) can take
    /// @param isFTUnwind isFTUnwind == true => the counterfactual unwind is in the Fixed Taker direction (from left to right along the VAMM), the opposite is true if isFTUnwind == false
    function getAbsoluteFixedTokenDeltaUnbalancedSimulatedUnwind(
        uint256 variableTokenDeltaAbsolute,
        uint160 sqrtRatioCurrX96,
        uint256 startingFixedRateMultiplierWad,
        uint256 fixedRateDeviationMinWad,
        bool isFTUnwind
    ) internal view returns (uint256 fixedTokenDeltaUnbalanced) {
        /// @dev fixedRateDeviationMinWad is in percentage points

        // calculate fixedRateStart

        uint256 sqrtRatioCurrWad = FullMath.mulDiv(
            ONE_UINT,
            FixedPoint96.Q96,
            sqrtRatioCurrX96
        );

        /// @dev fixedRateStartWad is in percentage points

        uint256 fixedRateStartWad = sqrtRatioCurrWad.mul(sqrtRatioCurrWad);

        // calculate D (from the litepaper)
        uint256 upperDWad = fixedRateStartWad.mul(
            startingFixedRateMultiplierWad
        );

        // calculate d (from the litepaper)

        uint256 dWad = (
            (upperDWad < fixedRateDeviationMinWad)
                ? fixedRateDeviationMinWad
                : upperDWad
        ).mul(
                (ONE -
                    (_termEndTimestampWad - Time.blockTimestampScaled())
                        .div(uint256(marginCalculatorParameters.tMaxWad))
                        .toInt256()
                        .mul(-marginCalculatorParameters.gammaWad.toInt256())
                        .exp()).toUint256()
            );

        // calculate counterfactual fixed rate

        uint256 fixedRateCFWad;
        if (isFTUnwind) {
            if (fixedRateStartWad > dWad) {
                if (fixedRateStartWad > WORST_CASE_FIXED_RATE_WAD) {
                    fixedRateCFWad = WORST_CASE_FIXED_RATE_WAD - dWad;
                } else {
                    fixedRateCFWad = fixedRateStartWad - dWad;
                }
            } else {
                fixedRateCFWad = 0;
            }
        } else {
            fixedRateCFWad = fixedRateStartWad + dWad;
        }
        // calculate fixedTokenDeltaUnbalanced

        fixedTokenDeltaUnbalanced = variableTokenDeltaAbsolute
            .fromUint()
            .mul(fixedRateCFWad)
            .toUint();
    }

    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    struct PositionMarginRequirementLocalVars2 {
        int24 inRangeTick;
        int256 scenario1LPVariableTokenBalance;
        int256 scenario1LPFixedTokenBalance;
        uint160 scenario1SqrtPriceX96;
        int256 scenario2LPVariableTokenBalance;
        int256 scenario2LPFixedTokenBalance;
        uint160 scenario2SqrtPriceX96;
    }

    function initialize(
        IERC20Minimal __underlyingToken,
        IRateOracle __rateOracle,
        uint256 __termStartTimestampWad,
        uint256 __termEndTimestampWad
    ) external override initializer {
        require(address(__underlyingToken) != address(0), "UT");
        require(address(__rateOracle) != address(0), "RO");
        require(__termStartTimestampWad != 0, "TS");
        require(__termEndTimestampWad != 0, "TE");
        require(__termEndTimestampWad > __termStartTimestampWad, "TE<=TS");

        _underlyingToken = __underlyingToken;
        _termStartTimestampWad = __termStartTimestampWad;
        _termEndTimestampWad = __termEndTimestampWad;

        _rateOracle = __rateOracle;
        _factory = IFactory(msg.sender);

        // Todo: set default values for things like _secondsAgo, cacheMaxAge.
        // We should see if we need to do any similar defaulting for VAMM, FCM
        // _secondsAgo = 2 weeks; // can be changed by owner
        // _cacheMaxAgeInSeconds = 6 hours; // can be changed by owner

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // To authorize the owner to upgrade the contract we implement _authorizeUpgrade with the onlyOwner modifier.
    // ref: https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier nonZeroDelta(int256 marginDelta) {
        if (marginDelta == 0) {
            revert CustomErrors.InvalidMarginDelta();
        }
        _;
    }

    /// @dev Modifier that ensures only the VAMM can execute certain actions
    modifier onlyVAMM() {
        if (msg.sender != address(_vamm)) {
            revert CustomErrors.OnlyVAMM();
        }
        _;
    }

    /// @dev Modifier that reverts if the msg.sender is not the Full Collateralisation Module
    modifier onlyFCM() {
        if (msg.sender != address(_fcm)) {
            revert CustomErrors.OnlyFCM();
        }
        _;
    }

    /// @dev Modifier that reverts if the termEndTimestamp is higher than the current block timestamp
    /// @dev This modifier ensures that actions such as settlePosition (can only be done after maturity)
    modifier onlyAfterMaturity() {
        if (_termEndTimestampWad > Time.blockTimestampScaled()) {
            revert CustomErrors.CannotSettleBeforeMaturity();
        }
        _;
    }

    /// @dev Modifier that ensures new LP positions cannot be minted after one day before the maturity of the vamm
    /// @dev also ensures new swaps cannot be conducted after one day before maturity of the vamm
    modifier checkCurrentTimestampTermEndTimestampDelta() {
        if (Time.isCloseToMaturityOrBeyondMaturity(_termEndTimestampWad)) {
            revert CustomErrors.closeToOrBeyondMaturity();
        }
        _;
    }

    // GETTERS FOR STORAGE SLOTS
    // Not auto-generated by public variables in the storage contract, cos solidity doesn't support that for functions that implement an interface
    /// @inheritdoc IMarginEngine
    function termStartTimestampWad() external view override returns (uint256) {
        return _termStartTimestampWad;
    }

    /// @inheritdoc IMarginEngine
    function termEndTimestampWad() external view override returns (uint256) {
        return _termEndTimestampWad;
    }

    /// @inheritdoc IMarginEngine
    function lookbackWindowInSeconds()
        external
        view
        override
        returns (uint256)
    {
        return _secondsAgo;
    }

    /// @inheritdoc IMarginEngine
    function cacheMaxAgeInSeconds() external view override returns (uint256) {
        return _cacheMaxAgeInSeconds;
    }

    /// @inheritdoc IMarginEngine
    function liquidatorRewardWad() external view override returns (uint256) {
        return _liquidatorRewardWad;
    }

    /// @inheritdoc IMarginEngine
    function underlyingToken() external view override returns (IERC20Minimal) {
        return _underlyingToken;
    }

    /// @inheritdoc IMarginEngine
    function fcm() external view override returns (IFCM) {
        return _fcm;
    }

    /// @inheritdoc IMarginEngine
    function vamm() external view override returns (IVAMM) {
        return _vamm;
    }

    /// @inheritdoc IMarginEngine
    function factory() external view override returns (IFactory) {
        return _factory;
    }

    /// @inheritdoc IMarginEngine
    function rateOracle() external view override returns (IRateOracle) {
        return _rateOracle;
    }

    /// @inheritdoc IMarginEngine
    function setMarginCalculatorParameters(
        MarginCalculatorParameters memory _marginCalculatorParameters
    ) external override onlyOwner {
        marginCalculatorParameters = _marginCalculatorParameters;
        emit MarginCalculatorParametersSetting(marginCalculatorParameters);
    }

    /// @inheritdoc IMarginEngine
    function setVAMM(IVAMM _vAMM) external override onlyOwner {
        _vamm = _vAMM;
        emit VAMMSetting(_vamm);
    }

    /// @inheritdoc IMarginEngine
    function setRateOracle(IRateOracle __rateOracle)
        external
        override
        onlyOwner
    {
        _rateOracle = __rateOracle;
        emit RateOracleSetting(_rateOracle);
    }

    /// @inheritdoc IMarginEngine
    function setFCM(IFCM _newFCM) external override onlyOwner {
        _fcm = _newFCM;
        emit FCMSetting(_fcm);
    }

    /// @inheritdoc IMarginEngine
    function setLookbackWindowInSeconds(uint256 _newSecondsAgo)
        external
        override
        onlyOwner
    {
        require(
            (_newSecondsAgo <= MAX_LOOKBACK_WINDOW_IN_SECONDS) &&
                (_newSecondsAgo >= MIN_LOOKBACK_WINDOW_IN_SECONDS),
            "LB OOB"
        );

        if (_secondsAgo == 0) {
            // First time setting the value. Anything goes.
            _secondsAgo = _newSecondsAgo;
        } else {
            // Updating value. Invalidate cache and make sure we can read the rates we need from the rate oracle.
            _secondsAgo = _newSecondsAgo;

            // Cache invalidated
            _refreshHistoricalApyCache();
        }

        emit HistoricalApyWindowSetting(_secondsAgo);
    }

    /// @inheritdoc IMarginEngine
    function setCacheMaxAgeInSeconds(uint256 _newCacheMaxAgeInSeconds)
        external
        override
        onlyOwner
    {
        require(
            _newCacheMaxAgeInSeconds <= MAX_CACHE_MAX_AGE_IN_SECONDS,
            "CMA OOB"
        );

        _cacheMaxAgeInSeconds = _newCacheMaxAgeInSeconds;
        emit CacheMaxAgeSetting(_cacheMaxAgeInSeconds);
    }

    /// @inheritdoc IMarginEngine
    function collectProtocol(address _recipient, uint256 _amount)
        external
        override
        whenNotPaused
        onlyOwner
    {
        if (_amount > 0) {
            /// @dev if the amount exceeds the available balances, _vamm.updateProtocolFees(amount) should be reverted as intended
            _vamm.updateProtocolFees(_amount);
            _underlyingToken.safeTransfer(_recipient, _amount);
        }

        emit ProtocolCollection(msg.sender, _recipient, _amount);
    }

    /// @inheritdoc IMarginEngine
    function setLiquidatorReward(uint256 _newLiquidatorRewardWad)
        external
        override
        onlyOwner
    {
        require(_newLiquidatorRewardWad <= MAX_LIQUIDATOR_REWARD_WAD, "LR OOB");

        _liquidatorRewardWad = _newLiquidatorRewardWad;
        emit LiquidatorRewardSetting(_liquidatorRewardWad);
    }

    /// @inheritdoc IMarginEngine
    function getPosition(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) external override returns (Position.Info memory) {
        Position.Info storage _position = positions.get(
            _owner,
            _tickLower,
            _tickUpper
        );
        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        ); // isMint=false
        return _position;
    }

    /// @notice _transferMargin function which:
    /// @dev Transfers funds in from account if _marginDelta is positive, or out to account if _marginDelta is negative
    /// @dev if the margiDelta is positive, we conduct a safe transfer from the _account address to the address of the MarginEngine
    /// @dev if the marginDelta is negative, the user wishes to withdraw underlying tokens from the MarginEngine,
    /// @dev in that case we first check the balance of the marginEngine in terms of the underlying tokens, if the balance is sufficient to cover the margin transfer, then we cover it via a safeTransfer
    /// @dev if the marginEngineBalance is not sufficient to cover the marginDelta then we cover the remainingDelta by invoking the transferMarginToMarginEngineTrader function of the fcm which in case of Aave will calls the Aave withdraw function to settle with the MarginEngine in underlying tokens
    function _transferMargin(address _account, int256 _marginDelta) internal {
        if (_marginDelta > 0) {
            _underlyingToken.safeTransferFrom(
                _account,
                address(this),
                uint256(_marginDelta)
            );
        } else {
            uint256 _marginEngineBalance = _underlyingToken.balanceOf(
                address(this)
            );

            uint256 _remainingDeltaToCover;
            unchecked {
                _remainingDeltaToCover = uint256(-_marginDelta);
            }

            if (_remainingDeltaToCover > _marginEngineBalance) {
                if (_marginEngineBalance > 0) {
                    _remainingDeltaToCover -= _marginEngineBalance;
                    _underlyingToken.safeTransfer(
                        _account,
                        _marginEngineBalance
                    );
                }
                _fcm.transferMarginToMarginEngineTrader(
                    _account,
                    _remainingDeltaToCover
                );
            } else {
                _underlyingToken.safeTransfer(_account, _remainingDeltaToCover);
            }
        }
    }

    /// @inheritdoc IMarginEngine
    function transferMarginToFCMTrader(address _account, uint256 _marginDelta)
        external
        override
        whenNotPaused
        onlyFCM
    {
        _underlyingToken.safeTransfer(_account, _marginDelta);
    }

    /// @inheritdoc IMarginEngine
    function isAlpha() external view override returns (bool) {
        return _isAlpha;
    }

    /// @inheritdoc IMarginEngine
    function setIsAlpha(bool __isAlpha) external override onlyOwner {
        _isAlpha = __isAlpha;
        emit IsAlpha(_isAlpha);
    }

    /// @inheritdoc IMarginEngine
    function updatePositionMargin(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper,
        int256 _marginDelta
    ) external override whenNotPaused nonZeroDelta(_marginDelta) {
        require(_owner != address(0), "O0");

        Tick.checkTicks(_tickLower, _tickUpper);

        Position.Info storage _position = positions.get(
            _owner,
            _tickLower,
            _tickUpper
        );

        /// @dev if in alpha --> revert (unless call via periphery)
        if (_isAlpha) {
            IPeriphery _periphery = _factory.periphery();
            require(msg.sender == address(_periphery), "pphry only");
        }

        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        ); // isMint=false

        if (_marginDelta < 0) {
            if (
                _owner != msg.sender && !_factory.isApproved(_owner, msg.sender)
            ) {
                revert CustomErrors.OnlyOwnerCanUpdatePosition();
            }

            _position.updateMarginViaDelta(_marginDelta);

            _checkPositionMarginCanBeUpdated(_position, _tickLower, _tickUpper);

            _transferMargin(_owner, _marginDelta);
        } else {
            _position.updateMarginViaDelta(_marginDelta);

            _transferMargin(msg.sender, _marginDelta);
        }

        _position.rewardPerAmount = 0;

        emit PositionMarginUpdate(
            msg.sender,
            _owner,
            _tickLower,
            _tickUpper,
            _marginDelta
        );

        emit PositionUpdate(
            _owner,
            _tickLower,
            _tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );
    }

    /// @inheritdoc IMarginEngine
    function settlePosition(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) external override whenNotPaused onlyAfterMaturity {
        Tick.checkTicks(_tickLower, _tickUpper);

        Position.Info storage _position = positions.get(
            _owner,
            _tickLower,
            _tickUpper
        );

        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        );

        int256 _settlementCashflow = FixedAndVariableMath
            .calculateSettlementCashflow(
                _position.fixedTokenBalance,
                _position.variableTokenBalance,
                _termStartTimestampWad,
                _termEndTimestampWad,
                _rateOracle.variableFactor(
                    _termStartTimestampWad,
                    _termEndTimestampWad
                )
            );

        _position.updateBalancesViaDeltas(
            -_position.fixedTokenBalance,
            -_position.variableTokenBalance
        );
        _position.updateMarginViaDelta(_settlementCashflow);
        _position.settlePosition();

        emit PositionSettlement(
            _owner,
            _tickLower,
            _tickUpper,
            _settlementCashflow
        );

        emit PositionUpdate(
            _owner,
            _tickLower,
            _tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );
    }

    /// @inheritdoc IMarginEngine
    function getHistoricalApy() public override returns (uint256) {
        if (
            block.timestamp - cachedHistoricalApyWadRefreshTimestamp >
            _cacheMaxAgeInSeconds
        ) {
            // Cache is stale
            _refreshHistoricalApyCache();
            emit HistoricalApy(cachedHistoricalApyWad);
        }
        return cachedHistoricalApyWad;
    }

    /// @inheritdoc IMarginEngine
    function getHistoricalApyReadOnly() public view returns (uint256) {
        if (
            block.timestamp - cachedHistoricalApyWadRefreshTimestamp >
            _cacheMaxAgeInSeconds
        ) {
            // Cache is stale
            return _getHistoricalApy();
        }
        return cachedHistoricalApyWad;
    }

    /// @notice Computes the historical APY value of the RateOracle
    /// @dev The lookback window used by this function is determined by the _secondsAgo state variable
    function _getHistoricalApy() internal view returns (uint256) {
        uint256 _from = block.timestamp - _secondsAgo;

        uint256 historicalApy = _rateOracle.getApyFromTo(
            _from,
            block.timestamp
        );
        return historicalApy;
    }

    /// @notice Updates the cached historical APY value of the RateOracle even if the cache is not stale
    function _refreshHistoricalApyCache() internal {
        cachedHistoricalApyWad = _getHistoricalApy();
        cachedHistoricalApyWadRefreshTimestamp = block.timestamp;
    }

    /// @inheritdoc IMarginEngine
    function liquidatePosition(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    )
        external
        override
        whenNotPaused
        checkCurrentTimestampTermEndTimestampDelta
        returns (uint256)
    {
        /// @dev can only happen before maturity, this is checked when an unwind is triggered which in turn triggers a swap which checks for this condition

        Tick.checkTicks(_tickLower, _tickUpper);

        Position.Info storage _position = positions.get(
            _owner,
            _tickLower,
            _tickUpper
        );

        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        ); // isMint=false

        (bool _isLiquidatable, ) = _isLiquidatablePosition(
            _position,
            _tickLower,
            _tickUpper
        );

        if (!_isLiquidatable) {
            revert CannotLiquidate();
        }

        if (_position.rewardPerAmount == 0) {
            uint256 _absVariableTokenBalance = _position.variableTokenBalance <
                0
                ? uint256(-_position.variableTokenBalance)
                : uint256(_position.variableTokenBalance);
            if (_position.margin > 0) {
                _position.rewardPerAmount = PRBMathUD60x18.div(
                    PRBMathUD60x18.mul(
                        uint256(_position.margin),
                        _liquidatorRewardWad
                    ),
                    _absVariableTokenBalance
                );
            } else {
                _position.rewardPerAmount = 0;
            }
        }

        uint256 _liquidatorRewardValue = 0;
        if (_position._liquidity > 0) {
            /// @dev pass position._liquidity to ensure all of the liqudity is burnt
            _vamm.burn(_owner, _tickLower, _tickUpper, _position._liquidity);
            _position.updateLiquidity(-int128(_position._liquidity));

            /// @dev liquidator reward for burning liquidity
            _liquidatorRewardValue += PRBMathUD60x18.mul(
                uint256(_position.margin),
                _liquidatorRewardWad
            );
        }

        int256 _variableTokenDelta = _unwindPosition(
            _position,
            _owner,
            _tickLower,
            _tickUpper
        );

        /// @dev liquidator reward for unwinding position
        if (_variableTokenDelta != 0) {
            _liquidatorRewardValue += (_variableTokenDelta < 0)
                ? PRBMathUD60x18.mul(
                    uint256(-_variableTokenDelta),
                    _position.rewardPerAmount
                )
                : PRBMathUD60x18.mul(
                    uint256(_variableTokenDelta),
                    _position.rewardPerAmount
                );
        }

        if (_liquidatorRewardValue > 0) {
            _position.updateMarginViaDelta(-_liquidatorRewardValue.toInt256());
            _underlyingToken.safeTransfer(msg.sender, _liquidatorRewardValue);
        }

        emit PositionLiquidation(
            _owner,
            _tickLower,
            _tickUpper,
            msg.sender,
            _variableTokenDelta,
            _liquidatorRewardValue
        );

        emit PositionUpdate(
            _owner,
            _tickLower,
            _tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );

        return _liquidatorRewardValue;
    }

    /// @inheritdoc IMarginEngine
    function updatePositionPostVAMMInducedMintBurn(
        IVAMM.ModifyPositionParams memory _params
    )
        external
        override
        whenNotPaused
        onlyVAMM
        returns (int256 _positionMarginRequirement)
    {
        Position.Info storage _position = positions.get(
            _params.owner,
            _params.tickLower,
            _params.tickUpper
        );

        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _params.tickLower,
            _params.tickUpper,
            true
        ); // isMint=true

        _position.updateLiquidity(_params.liquidityDelta);

        if (_params.liquidityDelta > 0) {
            _positionMarginRequirement = _checkPositionMarginAboveRequirement(
                _position,
                _params.tickLower,
                _params.tickUpper
            );
        }

        if (_position.rewardPerAmount >= 0) {
            _position.rewardPerAmount = 0;
        }

        emit PositionUpdate(
            _params.owner,
            _params.tickLower,
            _params.tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );
    }

    /// @inheritdoc IMarginEngine
    function updatePositionPostVAMMInducedSwap(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper,
        int256 _fixedTokenDelta,
        int256 _variableTokenDelta,
        uint256 _cumulativeFeeIncurred,
        int256 _fixedTokenDeltaUnbalanced
    )
        external
        override
        whenNotPaused
        onlyVAMM
        returns (int256 _positionMarginRequirement)
    {
        /// @dev this function can only be called by the vamm following a swap

        Position.Info storage _position = positions.get(
            _owner,
            _tickLower,
            _tickUpper
        );
        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        ); // isMint=false

        /// @dev isUnwind means the trader is getting into a swap with the opposite direction to their net position
        /// @dev in that case it does not make sense to revert the transaction if the position margin requirement is not met since
        /// @dev it could have been even further from the requirement prior to the unwind
        bool _isUnwind = (_position.variableTokenBalance > 0 &&
            _variableTokenDelta < 0) ||
            (_position.variableTokenBalance < 0 && _variableTokenDelta > 0);

        if (_cumulativeFeeIncurred > 0) {
            _position.updateMarginViaDelta(-_cumulativeFeeIncurred.toInt256());
        }

        _position.updateBalancesViaDeltas(
            _fixedTokenDelta,
            _variableTokenDelta
        );

        _positionMarginRequirement = _getPositionMarginRequirement(
            _position,
            _tickLower,
            _tickUpper,
            false
        ).toInt256();

        /// @dev only check the margin requirement if it is not an unwind since an unwind could bring the position to a better state
        /// @dev and still not make it through the initial margin requirement
        if ((_positionMarginRequirement > _position.margin) && !_isUnwind) {
            IVAMM.VAMMVars memory _v = _vamm.vammVars();
            revert CustomErrors.MarginRequirementNotMet(
                _positionMarginRequirement,
                _v.tick,
                _fixedTokenDelta,
                _variableTokenDelta,
                _cumulativeFeeIncurred,
                _fixedTokenDeltaUnbalanced
            );
        }

        _position.rewardPerAmount = 0;

        emit PositionUpdate(
            _owner,
            _tickLower,
            _tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );
    }

    /// @notice update position token balances and account for fees
    /// @dev if the _liquidity of the position supplied to this function is >0 then we
    /// @dev 1. retrieve the fixed, variable and fee Growth variables from the vamm by invoking the computeGrowthInside function of the VAMM
    /// @dev 2. calculate the deltas that need to be applied to the position's fixed and variable token balances by taking into account trades that took place in the VAMM since the last mint/poke/burn that invoked this function
    /// @dev 3. update the fixed and variable token balances and the margin of the position to account for deltas (outlined above) and fees generated by the active liquidity supplied by the position
    /// @dev 4. additionally, we need to update the last growth inside variables in the Position.Info struct so that we take a note that we've accounted for the changes up until this point
    /// @dev if _liquidity of the position supplied to this function is zero, then we need to check if isMintBurn is set to true (if it is set to true) then we know this function was called post a mint/burn event,
    /// @dev meaning we still need to correctly update the last fixed, variable and fee growth variables in the Position.Info struct
    function _updatePositionTokenBalancesAndAccountForFees(
        Position.Info storage _position,
        int24 _tickLower,
        int24 _tickUpper,
        bool _isMintBurn
    ) internal {
        if (_position._liquidity > 0) {
            (
                int256 _fixedTokenGrowthInsideX128,
                int256 _variableTokenGrowthInsideX128,
                uint256 _feeGrowthInsideX128
            ) = _vamm.computeGrowthInside(_tickLower, _tickUpper);
            (int256 _fixedTokenDelta, int256 _variableTokenDelta) = _position
                .calculateFixedAndVariableDelta(
                    _fixedTokenGrowthInsideX128,
                    _variableTokenGrowthInsideX128
                );
            uint256 _feeDelta = _position.calculateFeeDelta(
                _feeGrowthInsideX128
            );

            _position.updateBalancesViaDeltas(
                _fixedTokenDelta - 1,
                _variableTokenDelta - 1
            );
            _position.updateFixedAndVariableTokenGrowthInside(
                _fixedTokenGrowthInsideX128,
                _variableTokenGrowthInsideX128
            );
            /// @dev collect fees
            if (_feeDelta > 0) {
                _position.accumulatedFees += _feeDelta - 1;
                _position.updateMarginViaDelta(_feeDelta.toInt256() - 1);
            }

            _position.updateFeeGrowthInside(_feeGrowthInsideX128);
        } else {
            if (_isMintBurn) {
                (
                    int256 _fixedTokenGrowthInsideX128,
                    int256 _variableTokenGrowthInsideX128,
                    uint256 _feeGrowthInsideX128
                ) = _vamm.computeGrowthInside(_tickLower, _tickUpper);
                _position.updateFixedAndVariableTokenGrowthInside(
                    _fixedTokenGrowthInsideX128,
                    _variableTokenGrowthInsideX128
                );
                _position.updateFeeGrowthInside(_feeGrowthInsideX128);
            }
        }
    }

    /// @notice Internal function that checks if the position's current margin is above the requirement
    /// @param _position Position.Info of the position of interest, updates to position, edit it in storage
    /// @param _tickLower Lower Tick of the position
    /// @param _tickUpper Upper Tick of the position
    /// @dev This function calculates the position margin requirement, compares it with the position.margin and reverts if the current position margin is below the requirement
    function _checkPositionMarginAboveRequirement(
        Position.Info storage _position,
        int24 _tickLower,
        int24 _tickUpper
    ) internal returns (int256 _positionMarginRequirement) {
        _positionMarginRequirement = _getPositionMarginRequirement(
            _position,
            _tickLower,
            _tickUpper,
            false
        ).toInt256();

        if (_position.margin <= _positionMarginRequirement) {
            revert CustomErrors.MarginLessThanMinimum(
                _positionMarginRequirement
            );
        }
    }

    /// @notice Check the position margin can be updated
    /// @param _position Position.Info of the position of interest, updates to position, edit it in storage
    /// @param _tickLower Lower Tick of the position
    /// @param _tickUpper Upper Tick of the position
    function _checkPositionMarginCanBeUpdated(
        Position.Info storage _position,
        int24 _tickLower,
        int24 _tickUpper
    ) internal {
        /// @dev If the IRS AMM has reached maturity, the only reason why someone would want to update
        /// @dev their margin is to withdraw it completely. If so, the position needs to be settled
        if (Time.blockTimestampScaled() >= _termEndTimestampWad) {
            if (!_position.isSettled) {
                revert CustomErrors.PositionNotSettled();
            }
            if (_position.margin < 0) {
                revert CustomErrors.WithdrawalExceedsCurrentMargin();
            }
        } else {
            /// @dev if we haven't reached maturity yet, then check if the position margin requirement is satisfied if not then the position margin update will also revert
            _checkPositionMarginAboveRequirement(
                _position,
                _tickLower,
                _tickUpper
            );
        }
    }

    /// @notice Unwind a position
    /// @dev Before unwinding a position, need to check if it is even necessary to unwind it, i.e. check if the most up to date variable token balance of a position is non-zero
    /// @dev If the current variable token balance is negative, then it means the position is a net Fixed Taker
    /// @dev Hence to unwind, we need to enter into a Variable Taker IRS contract with notional = abs(current variable token balance of the position)
    /// @param _owner the owner of the position
    /// @param _tickLower the lower tick of the position's tick range
    /// @param _tickUpper the upper tick of the position's tick range
    function _unwindPosition(
        Position.Info storage _position,
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) internal returns (int256 _variableTokenDelta) {
        Tick.checkTicks(_tickLower, _tickUpper);

        if (_position.variableTokenBalance != 0) {
            int256 _fixedTokenDelta;
            uint256 _cumulativeFeeIncurred;

            /// @dev initiate a swap

            bool _isFT = _position.variableTokenBalance < 0;

            /// @dev if isFT
            /// @dev get into a Variable Taker swap (the opposite of LP's current position) --> hence params.isFT is set to false for the vamm swap call
            /// @dev amountSpecified needs to be negative (since getting into a variable taker swap)
            /// @dev since the position.variableTokenBalance is already negative, pass position.variableTokenBalance as amountSpecified
            /// @dev since moving from left to right along the virtual amm, sqrtPriceLimit is set to MIN_SQRT_RATIO + 1
            /// @dev isExternal is a boolean that ensures the state updates to the position are handled directly in the body of the unwind call
            /// @dev that's more efficient than letting the swap call the margin engine again to update position fixed and varaible token balances + account for fees
            /// @dev if !isFT
            /// @dev get into a Fixed Taker swap (the opposite of LP's current position)
            /// @dev amountSpecified needs to be positive, since we are executing a fixedd taker swap
            /// @dev since the position.variableTokenBalance is already positive, pass position.variableTokenBalance as amountSpecified
            /// @dev since moving from right to left along the virtual amm, sqrtPriceLimit is set to MAX_SQRT_RATIO - 1

            IVAMM.SwapParams memory _params = IVAMM.SwapParams({
                recipient: _owner,
                amountSpecified: _position.variableTokenBalance,
                sqrtPriceLimitX96: _isFT
                    ? TickMath.MIN_SQRT_RATIO + 1
                    : TickMath.MAX_SQRT_RATIO - 1,
                tickLower: _tickLower,
                tickUpper: _tickUpper
            });

            (
                _fixedTokenDelta,
                _variableTokenDelta,
                _cumulativeFeeIncurred,
                ,

            ) = _vamm.swap(_params);

            if (_cumulativeFeeIncurred > 0) {
                /// @dev update position margin to account for the fees incurred while conducting a swap in order to unwind
                _position.updateMarginViaDelta(
                    -_cumulativeFeeIncurred.toInt256()
                );
            }

            /// @dev passes the _fixedTokenBalance and _variableTokenBalance deltas
            _position.updateBalancesViaDeltas(
                _fixedTokenDelta,
                _variableTokenDelta
            );
        }
    }

    function _getExtraBalances(
        int24 _fromTick,
        int24 _toTick,
        uint128 _liquidity,
        uint256 _variableFactorWad
    )
        internal
        view
        returns (
            int256 _extraFixedTokenBalance,
            int256 _extraVariableTokenBalance
        )
    {
        if (_fromTick == _toTick) return (0, 0);

        uint160 _sqrtRatioAtFromTickX96 = TickMath.getSqrtRatioAtTick(
            _fromTick
        );
        uint160 _sqrtRatioAtToTickX96 = TickMath.getSqrtRatioAtTick(_toTick);

        int256 _amount0 = SqrtPriceMath.getAmount0Delta(
            _sqrtRatioAtFromTickX96,
            _sqrtRatioAtToTickX96,
            (_fromTick < _toTick) ? -int128(_liquidity) : int128(_liquidity)
        );

        int256 _amount1 = SqrtPriceMath.getAmount1Delta(
            _sqrtRatioAtFromTickX96,
            _sqrtRatioAtToTickX96,
            (_fromTick < _toTick) ? int128(_liquidity) : -int128(_liquidity)
        );

        _extraFixedTokenBalance = FixedAndVariableMath.getFixedTokenBalance(
            _amount0,
            _amount1,
            _variableFactorWad,
            _termStartTimestampWad,
            _termEndTimestampWad
        );

        _extraVariableTokenBalance = _amount1;
    }

    /// @notice Get Position Margin Requirement
    /// @dev if the position has no active liquidity in the VAMM, then we can compute its margin requirement by just passing its current fixed and variable token balances to the getMarginRequirement function
    /// @dev however, if the current _liquidity of the position is positive, it means that the position can potentially enter into interest rate swap positions with traders in their tick range
    /// @dev to account for that possibility, we analyse two scenarios:
    /// @dev scenario 1: a trader comes in and trades all the liquidity all the way to the the upper tick
    /// @dev scenario 2: a trader comes in and trades all the liquidity all the way to the the lower tick
    /// @dev one the fixed and variable token balances are calculated for each counterfactual scenarios, their margin requiremnets can be obtained by calling getMarginrRequirement for each scenario
    /// @dev finally, the output is the max of the margin requirements from two of the scenarios considered
    function _getPositionMarginRequirement(
        Position.Info storage _position,
        int24 _tickLower,
        int24 _tickUpper,
        bool _isLM
    ) internal returns (uint256 _margin) {
        Tick.checkTicks(_tickLower, _tickUpper);

        IVAMM.VAMMVars memory _vammVars = _vamm.vammVars();
        uint160 _sqrtPriceX96 = _vammVars.sqrtPriceX96;
        int24 _tick = _vammVars.tick;

        uint256 _variableFactorWad = _rateOracle.variableFactor(
            _termStartTimestampWad,
            _termEndTimestampWad
        );

        if (_position._liquidity > 0) {
            PositionMarginRequirementLocalVars2 memory _localVars;
            _localVars.inRangeTick = (_tick < _tickLower)
                ? _tickLower
                : ((_tick < _tickUpper) ? _tick : _tickUpper);

            // scenario 1: a trader comes in and trades all the liquidity all the way to the the upper tick
            // scenario 2: a trader comes in and trades all the liquidity all the way to the the lower tick

            int256 _extraFixedTokenBalance;
            int256 _extraVariableTokenBalance;

            if (_tick < _tickUpper) {
                (
                    _extraFixedTokenBalance,
                    _extraVariableTokenBalance
                ) = _getExtraBalances(
                    _localVars.inRangeTick,
                    _tickUpper,
                    _position._liquidity,
                    _variableFactorWad
                );
            }

            _localVars.scenario1LPVariableTokenBalance =
                _position.variableTokenBalance +
                _extraVariableTokenBalance;

            _localVars.scenario1LPFixedTokenBalance =
                _position.fixedTokenBalance +
                _extraFixedTokenBalance;

            if (_tick > _tickLower) {
                (
                    _extraFixedTokenBalance,
                    _extraVariableTokenBalance
                ) = _getExtraBalances(
                    _localVars.inRangeTick,
                    _tickLower,
                    _position._liquidity,
                    _variableFactorWad
                );
            } else {
                (_extraFixedTokenBalance, _extraVariableTokenBalance) = (0, 0);
            }

            _localVars.scenario2LPVariableTokenBalance =
                _position.variableTokenBalance +
                _extraVariableTokenBalance;

            _localVars.scenario2LPFixedTokenBalance =
                _position.fixedTokenBalance +
                _extraFixedTokenBalance;

            uint160 _lowPrice = TickMath.getSqrtRatioAtTick(_tickLower);
            uint160 _highPrice = TickMath.getSqrtRatioAtTick(_tickUpper);
            _lowPrice = _sqrtPriceX96 < _lowPrice ? _sqrtPriceX96 : _lowPrice;
            _highPrice = _sqrtPriceX96 > _highPrice
                ? _sqrtPriceX96
                : _highPrice;

            _localVars.scenario1SqrtPriceX96 = (_localVars
                .scenario1LPVariableTokenBalance > 0)
                ? _highPrice
                : _lowPrice;

            _localVars.scenario2SqrtPriceX96 = (_localVars
                .scenario2LPVariableTokenBalance > 0)
                ? _highPrice
                : _lowPrice;

            uint256 _scenario1MarginRequirement = _getMarginRequirement(
                _localVars.scenario1LPFixedTokenBalance,
                _localVars.scenario1LPVariableTokenBalance,
                _isLM,
                _localVars.scenario1SqrtPriceX96
            );
            uint256 _scenario2MarginRequirement = _getMarginRequirement(
                _localVars.scenario2LPFixedTokenBalance,
                _localVars.scenario2LPVariableTokenBalance,
                _isLM,
                _localVars.scenario2SqrtPriceX96
            );

            if (_scenario1MarginRequirement > _scenario2MarginRequirement) {
                return _scenario1MarginRequirement;
            } else {
                return _scenario2MarginRequirement;
            }
        } else {
            // directly get the trader margin requirement
            return
                _getMarginRequirement(
                    _position.fixedTokenBalance,
                    _position.variableTokenBalance,
                    _isLM,
                    _sqrtPriceX96
                );
        }
    }

    /// @notice Checks if a given position is liquidatable
    /// @dev In order for a position to be liquidatable its current margin needs to be lower than the position's liquidation margin requirement
    /// @return _isLiquidatable A boolean which suggests if a given position is liquidatable
    function _isLiquidatablePosition(
        Position.Info storage _position,
        int24 _tickLower,
        int24 _tickUpper
    ) internal returns (bool, int256) {
        int256 _marginRequirement = _getPositionMarginRequirement(
            _position,
            _tickLower,
            _tickUpper,
            true
        ).toInt256();

        /// @audit overflow is possible
        return (_position.margin < _marginRequirement, _marginRequirement);
    }

    /// @notice Returns either the Liquidation or Initial Margin Requirement given a fixed and variable token balance as well as the isLM boolean
    /// @return _margin  either liquidation or initial margin requirement of a given trader in terms of the underlying tokens
    function _getMarginRequirement(
        int256 _fixedTokenBalance,
        int256 _variableTokenBalance,
        bool _isLM,
        uint160 _sqrtPriceX96
    ) internal returns (uint256 _margin) {
        _margin = __getMarginRequirement(
            _fixedTokenBalance,
            _variableTokenBalance,
            _isLM
        );

        uint256 _minimumMarginRequirement = _getMinimumMarginRequirement(
            _fixedTokenBalance,
            _variableTokenBalance,
            _isLM,
            _sqrtPriceX96
        );

        if (_margin < _minimumMarginRequirement) {
            _margin = _minimumMarginRequirement;
        }
    }

    /// @notice get margin requirement based on a fixed and variable token balance and isLM boolean
    function __getMarginRequirement(
        int256 _fixedTokenBalance,
        int256 _variableTokenBalance,
        bool _isLM
    ) internal returns (uint256 _margin) {
        if (_fixedTokenBalance >= 0 && _variableTokenBalance >= 0) {
            return 0;
        }

        int256 _fixedTokenBalanceWad = PRBMathSD59x18.fromInt(
            _fixedTokenBalance
        );
        int256 _variableTokenBalanceWad = PRBMathSD59x18.fromInt(
            _variableTokenBalance
        );

        /// exp1 = fixedTokenBalance*timeInYearsFromTermStartToTermEnd*0.01
        // this can either be negative or positive depending on the sign of the fixedTokenBalance
        int256 _exp1Wad = PRBMathSD59x18.mul(
            _fixedTokenBalanceWad,
            FixedAndVariableMath
                .fixedFactor(true, _termStartTimestampWad, _termEndTimestampWad)
                .toInt256()
        );

        /// exp2 = variableTokenBalance*worstCaseVariableFactor(from term start to term end)
        // todo: minimise gas cost of the scenario where the balance is 0
        int256 _exp2Wad = 0;
        if (_variableTokenBalance != 0) {
            _exp2Wad = PRBMathSD59x18.mul(
                _variableTokenBalanceWad,
                worstCaseVariableFactorAtMaturity(
                    _variableTokenBalance < 0,
                    _isLM,
                    getHistoricalApy()
                ).toInt256()
            );
        }

        // this is the worst case settlement cashflow expected by the position to cover
        int256 _maxCashflowDeltaToCoverPostMaturity = _exp1Wad + _exp2Wad;

        // hence if maxCashflowDeltaToCoverPostMaturity is negative then the margin needs to be sufficient to cover it
        // if maxCashflowDeltaToCoverPostMaturity is non-negative then it means according to this model the even in the worst case, the settlement cashflow is expected to be non-negative
        // hence, returning zero as the margin requirement
        if (_maxCashflowDeltaToCoverPostMaturity < 0) {
            _margin = PRBMathUD60x18.toUint(
                uint256(-_maxCashflowDeltaToCoverPostMaturity)
            );
        } else {
            _margin = 0;
        }
    }

    /// @notice Get Minimum Margin Requirement
    // given the fixed and variable balances and a starting sqrtPriceX96
    // we calculate the minimum marign requirement by simulating a counterfactual unwind at fixed rate that is a function of the current fixed rate (sqrtPriceX96) (details in the litepaper)
    // if the variable token balance is 0 or if the variable token balance is >0 and the fixed token balace >0 then the minimum margin requirement is zero
    function _getMinimumMarginRequirement(
        int256 _fixedTokenBalance,
        int256 _variableTokenBalance,
        bool _isLM,
        uint160 _sqrtPriceX96
    ) internal returns (uint256 _margin) {
        if (_variableTokenBalance == 0) {
            // if the variable token balance is zero there is no need for a minimum liquidator incentive since a liquidtion is not expected
            return 0;
        }

        int256 _fixedTokenDeltaUnbalanced;
        uint256 _devMulWad;
        uint256 _fixedRateDeviationMinWad;
        uint256 _absoluteVariableTokenBalance;
        bool _isVariableTokenBalancePositive;

        if (_variableTokenBalance > 0) {
            if (_fixedTokenBalance > 0) {
                // if both are positive, no need to have a margin requirement
                return 0;
            }

            if (_isLM) {
                _devMulWad = marginCalculatorParameters.devMulLeftUnwindLMWad;
                _fixedRateDeviationMinWad = marginCalculatorParameters
                    .fixedRateDeviationMinLeftUnwindLMWad;
            } else {
                _devMulWad = marginCalculatorParameters.devMulLeftUnwindIMWad;
                _fixedRateDeviationMinWad = marginCalculatorParameters
                    .fixedRateDeviationMinLeftUnwindIMWad;
            }

            _absoluteVariableTokenBalance = uint256(_variableTokenBalance);
            _isVariableTokenBalancePositive = true;
        } else {
            if (_isLM) {
                _devMulWad = marginCalculatorParameters.devMulRightUnwindLMWad;
                _fixedRateDeviationMinWad = marginCalculatorParameters
                    .fixedRateDeviationMinRightUnwindLMWad;
            } else {
                _devMulWad = marginCalculatorParameters.devMulRightUnwindIMWad;
                _fixedRateDeviationMinWad = marginCalculatorParameters
                    .fixedRateDeviationMinRightUnwindIMWad;
            }

            _absoluteVariableTokenBalance = uint256(-_variableTokenBalance);
        }

        // simulate an adversarial unwind (cumulative position is a Variable Taker --> simulate FT unwind --> movement to the left along the VAMM)
        // fixedTokenDelta unbalanced that results from the simulated unwind
        _fixedTokenDeltaUnbalanced = getAbsoluteFixedTokenDeltaUnbalancedSimulatedUnwind(
            uint256(_absoluteVariableTokenBalance),
            _sqrtPriceX96,
            _devMulWad,
            _fixedRateDeviationMinWad,
            _isVariableTokenBalancePositive
        ).toInt256();

        int256 _fixedTokenDelta = FixedAndVariableMath.getFixedTokenBalance(
            _isVariableTokenBalancePositive
                ? _fixedTokenDeltaUnbalanced
                : -_fixedTokenDeltaUnbalanced,
            -_variableTokenBalance,
            _rateOracle.variableFactor(
                _termStartTimestampWad,
                _termEndTimestampWad
            ),
            _termStartTimestampWad,
            _termEndTimestampWad
        );

        int256 _updatedFixedTokenBalance = _fixedTokenBalance +
            _fixedTokenDelta;

        _margin = __getMarginRequirement(_updatedFixedTokenBalance, 0, _isLM);

        if (
            _margin <
            marginCalculatorParameters.minMarginToIncentiviseLiquidators
        ) {
            _margin = marginCalculatorParameters
                .minMarginToIncentiviseLiquidators;
        }
    }

    function getPositionMarginRequirement(
        address _recipient,
        int24 _tickLower,
        int24 _tickUpper,
        bool _isLM
    ) external override returns (uint256) {
        Position.Info storage _position = positions.get(
            _recipient,
            _tickLower,
            _tickUpper
        );
        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        ); // isMint=false

        emit PositionUpdate(
            _recipient,
            _tickLower,
            _tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );

        return
            _getPositionMarginRequirement(
                _position,
                _tickLower,
                _tickUpper,
                _isLM
            );
    }
}