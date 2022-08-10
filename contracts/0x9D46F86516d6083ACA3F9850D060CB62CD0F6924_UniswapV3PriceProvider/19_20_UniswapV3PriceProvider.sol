// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

import "../../utils/TwoStepOwnable.sol";
import "../PriceProvider.sol";
import "../IERC20Like.sol";

/// @title UniswapV3PriceProvider
/// @notice Price provider contract that reads prices from UniswapV3
contract UniswapV3PriceProvider is PriceProvider, TwoStepOwnable {
    struct PriceCalculationData {
        // Number of seconds for which time-weighted average should be calculated, ie. 1800 means 30 min
        uint32 periodForAvgPrice;

        // Estimated blockchain block time
        uint8 blockTime;
    }

    bytes32 private constant _OLD_ERROR_HASH = keccak256(abi.encodeWithSignature("Error(string)", "OLD"));

    /// @dev this is basically `PriceProvider.quoteToken.decimals()`
    uint256 private immutable _QUOTE_TOKEN_DECIMALS; // solhint-disable-line var-name-mixedcase

    /// @dev block time is used to estimate the average number of blocks minted in `periodForAvgPrice`
    /// block time tends to go down (not up), temporary deviations are not important
    /// Ethereum's block time is almost never higher than ~15 sec, so in practice we shouldn't need to set it above that
    /// 60 was chosen as an arbitrary maximum just to prevent human errors
    uint256 private constant _MAX_ACCEPTED_BLOCK_TIME = 60;

    /// @dev UniswapV3 factory contract
    IUniswapV3Factory public immutable uniswapV3Factory;

    /// @dev priceCalculationData:
    /// - periodForAvgPrice: Number of seconds for which time-weighted average should be calculated, ie. 1800 is 30 min
    /// - blockTime: Estimated blockchain block time
    PriceCalculationData public priceCalculationData;

    /// @notice Maps asset address to UniV3 pool
    mapping(address => IUniswapV3Pool) public pools;

    /// @notice Emitted when TWAP period changes
    /// @param period new period in seconds, ie. 1800 means 30 min
    event NewPeriod(uint32 period);

    /// @notice Emitted when blockTime changes
    /// @param blockTime block time in seconds
    event NewBlockTime(uint8 blockTime);

    /// @notice Emitted when UniV3 pool is set for asset
    /// @param asset asset address
    /// @param pool UniV3 pool address
    event PoolForAsset(address indexed asset, IUniswapV3Pool indexed pool);

    /// @param _priceProvidersRepository address of PriceProvidersRepository
    /// @param _factory UniswapV3 factory contract
    /// @param _priceCalculationData:
    /// - _periodForAvgPrice period in seconds for TWAP price, ie. 1800 means 30 min
    /// - _blockTime estimated block time, it is better to set it bit lower than higher that avg block time
    ///   eg. if ETH block time is 13~13.5s, you can set it to 12s
    constructor(
        IPriceProvidersRepository _priceProvidersRepository,
        IUniswapV3Factory _factory,
        PriceCalculationData memory _priceCalculationData
    ) PriceProvider(_priceProvidersRepository) {
        uint24 defaultFee = 500;
        // Ping for _priceProvidersRepository is not needed here, because PriceProvider does it
        if (_factory.feeAmountTickSpacing(defaultFee) == 0) revert("InvalidFactory");
        if (_priceCalculationData.periodForAvgPrice == 0) revert("InvalidPeriodForAvgPrice");

        if (
            _priceCalculationData.blockTime == 0 || _priceCalculationData.blockTime >= _MAX_ACCEPTED_BLOCK_TIME
        ) {
            revert("InvalidBlockTime");
        }

        _validatePriceCalculationData(
            _priceCalculationData.periodForAvgPrice,
            _priceCalculationData.blockTime
        );

        uniswapV3Factory = _factory;
        priceCalculationData = _priceCalculationData;

        _QUOTE_TOKEN_DECIMALS = IERC20Like(_priceProvidersRepository.quoteToken()).decimals();
    }

    /// @notice Setup pool for asset. Use it also for update, when you want to change pool for asset.
    /// Notice: pool must be ready for providing price. See `adjustOracleCardinality`.
    /// @param _asset asset address
    /// @param _pool UniV3 pool address
    function setupAsset(address _asset, IUniswapV3Pool _pool) external onlyManager {
        verifyPool(_asset, _pool);

        pools[_asset] = _pool;
        emit PoolForAsset(_asset, _pool);

        // make sure getPrice does not revert
        getPrice(_asset);
    }

    /// @notice Change period for which to calculated TWAP prices
    /// @dev WARNING: when we increase this period, then UniV3 pool that is already initialized
    /// and set as oracle for asset, will not immediately adjust to new time window.
    /// We need to call `adjustOracleCardinality` and then wait for buffer to filled up.
    /// Until that happen, TWAP price will be fetched for shorter period (because of time window adjustment feature).
    /// @param _period new period in seconds, ie. 1800 means 30 min
    function changePeriodForAvgPrice(uint32 _period) external onlyManager {
        // `_period < block.timestamp` is because we making sure we do not underflow
        if (_period == 0 || _period >= block.timestamp) revert("InvalidPeriodForAvgPrice");
        if (priceCalculationData.periodForAvgPrice == _period) revert("PeriodForAvgPriceDidNotChange");

        _validatePriceCalculationData(_period, priceCalculationData.blockTime);

        priceCalculationData.periodForAvgPrice = _period;

        emit NewPeriod(_period);
    }

    /// @notice Change block time which is used to adjust oracle cardinality fot providing TWAP prices
    /// @param _blockTime it is better to set it bit lower than higher that avg block time
    /// eg. if ETH block time is 13~13.5s, you can set it to 11-12s
    /// based on `priceCalculationData.periodForAvgPrice` and `priceCalculationData.blockTime` price provider calculates
    /// number of blocks for (cardinality) requires for TWAP price. Unfortunately block time can change and this
    /// can lead to issues with getting price. Edge case will be when we set `_blockTime` to 1, then we have 100%
    /// guarantee, that no matter how real block time changes, we always can get price.
    /// Downside will be cost of initialization. That's why it is better to set a bit lower
    /// and adjust (decrease) in case of issues.
    function changeBlockTime(uint8 _blockTime) external onlyManager {
        if (_blockTime == 0 || _blockTime >= _MAX_ACCEPTED_BLOCK_TIME) revert("InvalidBlockTime");
        if (priceCalculationData.blockTime == _blockTime) revert("BlockTimeDidNotChange");

        _validatePriceCalculationData(priceCalculationData.periodForAvgPrice, _blockTime);

        priceCalculationData.blockTime = _blockTime;
        emit NewBlockTime(_blockTime);
    }

    /// @notice Adjust UniV3 pool cardinality to Silo's requirements.
    /// Call `observationsStatus` to see, if you need to execute this method.
    /// This method prepares pool for setup for price provider. In order to run `setupAsset` for asset,
    /// pool must have buffer to provide TWAP price. By calling this adjustment (and waiting necessary amount of time)
    /// pool will be ready for setup. It will collect valid number of observations, so the pool can be used
    /// once price data is ready.
    /// @dev Increases observation cardinality for univ3 oracle pool if needed, see getPrice desc for details.
    /// We should call it on init and when we are changing the pool (univ3 can have multiple pools for the same tokens)
    /// @param _pool UniV3 pool address
    function adjustOracleCardinality(IUniswapV3Pool _pool) external {
        (,,,, uint16 cardinalityNext,,) = _pool.slot0();
        PriceCalculationData memory data = priceCalculationData;

        // ideally we want to have data at every block during periodForAvgPrice
        // If we want to get TWAP for 5 minutes and assuming we have tx in every block, and block time is 15 sec,
        // then for 5 minutes we will have 20 blocks, that means our requiredCardinality is 20.
        uint256 requiredCardinality = data.periodForAvgPrice / data.blockTime;

        if (cardinalityNext >= requiredCardinality) revert("NotNecessary");

        // initialize required amount of slots, it will cost!
        _pool.increaseObservationCardinalityNext(uint16(requiredCardinality));
    }

    /// @inheritdoc IPriceProvider
    function assetSupported(address _asset) external view override returns (bool) {
        return address(pools[_asset]) != address(0) || _asset == quoteToken;
    }

    /// @notice This method can provide TWAP quote token price denominated in any other token
    /// it does NOT validate input pool, so you must be sure you providing correct one
    /// otherwise result will be wrong or function will throw.
    /// If pool is correct and it still throwing, please check `observationsStatus(_pool)`.
    /// @param _pool UniswapV3Pool address that can provide TWAP price and one of the tokens is native (quote) token
    function quotePrice(IUniswapV3Pool _pool) external view returns (uint256 price) {
        address base = quoteToken;
        address token0 = _pool.token0();
        address quote = base == token0 ? _pool.token1() : token0;
        uint128 baseAmount = uint128(10 ** _QUOTE_TOKEN_DECIMALS);

        int24 timeWeightedAverageTick = _consult(_pool);
        price = OracleLibrary.getQuoteAtTick(timeWeightedAverageTick, baseAmount, base, quote);
    }

    function assetOldestTimestamp(address _asset) external view returns (uint32 oldestTimestamp) {
        IUniswapV3Pool pool = pools[_asset];
        (,, uint16 observationIndex, uint16 currentObservationCardinality,,,) = pool.slot0();
        oldestTimestamp = resolveOldestObservationTimestamp(pool, observationIndex, currentObservationCardinality);
    }

    /// @notice Check if UniV3 pool has enough cardinality to meet Silo's requirements
    /// If it does not have, please execute `adjustOracleCardinality`.
    /// @param _pool UniV3 pool address
    /// @return bufferFull TRUE if buffer is ready to provide TWAP price rof required period
    /// @return enoughObservations TRUE if buffer has enough observations spots (they don't have to be filled up yet)
    function observationsStatus(IUniswapV3Pool _pool)
        public
        view
        returns (
            bool bufferFull,
            bool enoughObservations,
            uint16 currentCardinality
        )
    {
        PriceCalculationData memory data = priceCalculationData;

        (
            ,,, uint16 currentObservationCardinality,
            uint16 observationCardinalityNext,,
        ) = _pool.slot0();

        // ideally we want to have data at every block during periodForAvgPrice
        uint256 requiredCardinality = data.periodForAvgPrice / data.blockTime;

        bufferFull = currentObservationCardinality >= requiredCardinality;
        enoughObservations = observationCardinalityNext >= requiredCardinality;
        currentCardinality = currentObservationCardinality;
     }

    /// @dev It verifies, if provider pool for asset (and quote token) is valid.
    /// Throws when there is no pool or pool is empty (zero liquidity) or not ready for price
    /// @param _asset asset for which prices are going to be calculated
    /// @param _pool UniV3 pool address
    /// @return true if verification successful, otherwise throws
    function verifyPool(address _asset, IUniswapV3Pool _pool) public view returns (bool) {
        if (_asset == address(0)) revert("AssetIsZero");
        if (address(_pool) == address(0)) revert("PoolIsZero");

        address quote = quoteToken;
        uint24 fee = _pool.fee();

        if (uniswapV3Factory.getPool(_asset, quote, fee) != address(_pool)) revert("InvalidPoolForAsset");

        uint256 liquidity = IERC20Like(quote).balanceOf(address(_pool));
        if (liquidity == 0) revert("EmptyPool");

        (bool bufferFull,,) = observationsStatus(_pool);
        if (!bufferFull) revert("BufferNotFull");

        return true;
    }

    /// @dev UniV3 saves price only on: mint, burn and swap.
    /// Mint and burn will write observation only when "current tick is inside the passed range" of ticks.
    /// I think that means, that if we minting/burning outside ticks range  (so outside current price)
    /// it will not modify observation. So we left with swap.
    ///
    /// Swap will write observation under this condition:
    ///     // update tick and write an oracle entry if the tick change
    ///     if (state.tick != slot0Start.tick) {
    /// that means, it is possible that price will be up to date (in a range of same tick)
    /// but observation timestamp will be old.
    ///
    /// Every pool by default comes with just one slot for observation (cardinality == 1).
    /// We can increase number of slots so TWAP price will be "better".
    /// When we increase, we have to wait until new tx will write new observation.
    /// Based on all above, we can tell how old is observation, but this does not mean the price is wrong.
    /// UniV3 recommends to use `observe` and `OracleLibrary.consult` uses it.
    /// `observe` reverts if `secondsAgo` > oldest observation, means, if there is any price observation in selected
    /// time frame, it will revert. Otherwise it will return either exact TWAP price or by interpolation.
    ///
    /// Conclusion: we can choose how many observation pool will be storing, but we need to remember,
    /// not all of them might be used to provide our price. Final question is: how many observations we need?
    ///
    /// How UniV3 calculates TWAP
    /// we ask for TWAP on time range ago:now using `OracleLibrary.consult`, it is all about find the right tick
    /// - we call `IUniswapV3Pool(pool).observe(secondAgo)` that returns two accumulator values (for ago and now)
    /// - each observation is resolved by `observeSingle`
    ///   - for _now_ we just using latest observation, and if it does not match timestamp, we interpolate (!)
    ///     and this is how we got the _tickCumulative_, so in extreme situation, if last observation was made day ago,
    ///     UniV3 will interpolate to reflect _tickCumulative_ at current time
    ///   - for _ago_ we search for observation using `getSurroundingObservations` that give us
    ///     before and after observation, base on which we calculate "avg" and we have target _tickCumulative_
    ///     - getSurroundingObservations: it's job is to find 2 observations based on which we calculate tickCumulative
    ///       here is where all calculations can revert, if ago < oldest observation, otherwise it will be calculated
    ///       either by interpolation or we will have exact match
    /// - now with both _tickCumulative_s we calculating TWAP
    ///
    /// recommended observations are = 30 min / blockTime
    /// @inheritdoc IPriceProvider
    function getPrice(address _asset) public view override returns (uint256 price) {
        address quote = quoteToken;

        if (_asset == quote) {
            return 10 ** _QUOTE_TOKEN_DECIMALS;
        }

        uint256 decimals = IERC20Like(_asset).decimals();
        require(decimals <= 38, "power overflow"); // we need 10**decimals be less than 2**128

        uint256 baseAmount = 10 ** decimals;
        IUniswapV3Pool pool = pools[_asset];
        if (address(pool) == address(0)) revert("PoolNotSet");

        int24 timeWeightedAverageTick = _consult(pool);
        price = OracleLibrary.getQuoteAtTick(timeWeightedAverageTick, uint128(baseAmount), _asset, quote);
    }

    /// @param _pool uniswap V3 pool address
    /// @param _currentObservationIndex the most-recently updated index of the observations array
    /// @param _currentObservationCardinality the current maximum number of observations that are being stored
    /// @return oldestTimestamp last observation timestamp
    function resolveOldestObservationTimestamp(
        IUniswapV3Pool _pool,
        uint16 _currentObservationIndex,
        uint16 _currentObservationCardinality
    )
        public
        view
        returns (uint32 oldestTimestamp)
    {
        bool initialized;

        (
            oldestTimestamp,,,
            initialized
        ) = _pool.observations((_currentObservationIndex + 1) % _currentObservationCardinality);

        // if not initialized, we just check id#0 as this will be the oldest
        if (!initialized) {
            (oldestTimestamp,,,) = _pool.observations(0);
        }
    }

    /// @notice Fetches time-weighted average tick using Uniswap V3 oracle
    /// @dev this is based on `OracleLibrary.consult`, we adjusted it to handle `OLD` error, time window will adjust
    /// to available pool observations
    /// @param _pool Address of Uniswap V3 pool that we want to observe
    /// @return timeWeightedAverageTick time-weighted average tick from (block.timestamp - period) to block.timestamp
    function _consult(IUniswapV3Pool _pool) internal view returns (int24 timeWeightedAverageTick) {
        (uint32 period, int56[] memory tickCumulatives) = _calculatePeriodAndTicks(_pool);
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        timeWeightedAverageTick = int24(tickCumulativesDelta / period);

        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % period != 0)) timeWeightedAverageTick--;
    }

    /// @param _pool Address of Uniswap V3 pool
    /// @return period Number of seconds in the past to start calculating time-weighted average
    /// @return tickCumulatives Cumulative tick values as of each secondsAgos from the current block timestamp
    function _calculatePeriodAndTicks(IUniswapV3Pool _pool)
        internal
        view
        returns (uint32 period, int56[] memory tickCumulatives)
    {
        period = priceCalculationData.periodForAvgPrice;
        bool old;

        (tickCumulatives, old) = _observe(_pool, period);

        if (old) {
            (,, uint16 observationIndex, uint16 currentObservationCardinality,,,) = _pool.slot0();

            uint32 latestTimestamp =
                resolveOldestObservationTimestamp(_pool, observationIndex, currentObservationCardinality);

            period = uint32(block.timestamp - latestTimestamp);

            (tickCumulatives, old) = _observe(_pool, period);
            if (old) revert("STILL OLD");
        }
    }

    /// @param _pool UniV3 pool address
    /// @param _period Number of seconds in the past to start calculating time-weighted average
    function _observe(IUniswapV3Pool _pool, uint32 _period)
        internal
        view
        returns (int56[] memory tickCumulatives, bool old)
    {
        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = _period;
        // secondAgos[1] = 0; // default is 0

        try _pool.observe(secondAgos)
            returns (int56[] memory ticks, uint160[] memory)
        {
            tickCumulatives = ticks;
            old = false;
        }
        catch (bytes memory reason) {
            if (keccak256(reason) != _OLD_ERROR_HASH) _revertBytes(reason, "_observe");
            old = true;
        }
    }

    function _validatePriceCalculationData(uint32 _periodForAvgPrice, uint8 _blockTime) private pure {
        uint256 requiredCardinality = _periodForAvgPrice / _blockTime;
        if (requiredCardinality > type(uint16).max) revert("InvalidRequiredCardinality");
    }
}