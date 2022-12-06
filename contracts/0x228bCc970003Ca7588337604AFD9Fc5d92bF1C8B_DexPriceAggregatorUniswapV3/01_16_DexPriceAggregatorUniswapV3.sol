// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';

import './interfaces/IDexPriceAggregator.sol';
import './libraries/SafeCast.sol';
import './Owned.sol';

/// @title DexPriceAggregatorUniswapV3
/// @notice A DexPriceAggregator sourcing prices from Uniswap V3.
///         Provides the minimum output between an asset's "spot" price and TWAP from the last n seconds.
///         The "spot" price is always the last block's ending price.
contract DexPriceAggregatorUniswapV3 is IDexPriceAggregator, Owned {
    address public immutable uniswapV3Factory;
    address public immutable weth;
    uint24 public immutable defaultPoolFee;

    mapping(bytes32 => address) public overriddenPoolForRoute;

    constructor(
        address _owner,
        address _uniswapV3Factory,
        address _weth,
        uint24 _defaultPoolFee
    ) Owned(_owner) {
        uniswapV3Factory = _uniswapV3Factory;
        weth = _weth;
        defaultPoolFee = _defaultPoolFee;
    }

    /********************
     * Oracle functions *
     ********************/

    /// @inheritdoc IDexPriceAggregator
    function assetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _twapPeriod
    ) public view override returns (uint256 amountOut) {
        if (_tokenIn == weth) {
            return ethToAsset(_amountIn, _tokenOut, _twapPeriod);
        } else if (_tokenOut == weth) {
            return assetToEth(_tokenIn, _amountIn, _twapPeriod);
        } else {
            return _fetchAmountCrossingPools(_tokenIn, _amountIn, _tokenOut, _twapPeriod);
        }
    }

    /// @notice Given a token and its amount, return the equivalent value in ETH
    /// @param _tokenIn Address of an ERC20 token contract to be converted
    /// @param _amountIn Amount of tokenIn to be converted
    /// @param _twapPeriod Number of seconds in the past to consider for the TWAP rate
    /// @return ethAmountOut Amount of ETH received for amountIn of tokenIn
    function assetToEth(
        address _tokenIn,
        uint256 _amountIn,
        uint256 _twapPeriod
    ) public view returns (uint256 ethAmountOut) {
        address tokenOut = weth;
        address pool = _getPoolForRoute(PoolAddress.getPoolKey(_tokenIn, tokenOut, defaultPoolFee));
        return _fetchAmountFromSinglePool(_tokenIn, _amountIn, tokenOut, pool, _twapPeriod);
    }

    /// @notice Given an amount of ETH, return the equivalent value in another token
    /// @param _ethAmountIn Amount of ETH to be converted
    /// @param _tokenOut Address of an ERC20 token contract to convert into
    /// @param _twapPeriod Number of seconds in the past to consider for the TWAP rate
    /// @return amountOut Amount of tokenOut received for ethAmountIn of ETH
    function ethToAsset(
        uint256 _ethAmountIn,
        address _tokenOut,
        uint256 _twapPeriod
    ) public view returns (uint256 amountOut) {
        address tokenIn = weth;
        address pool = _getPoolForRoute(PoolAddress.getPoolKey(tokenIn, _tokenOut, defaultPoolFee));
        return _fetchAmountFromSinglePool(tokenIn, _ethAmountIn, _tokenOut, pool, _twapPeriod);
    }

    /************************
     * Management functions *
     ************************/

    /// @notice Override the Uniswap V3 pool queried on a tokenA:tokenB route
    /// @dev Override can be reset by using address(0) for _pool
    /// @param _tokenA Address of an ERC20 token contract
    /// @param _tokenB Address of another ERC20 token contract
    /// @param _pool Address of a Uniswap V3 pool constructed with _tokenA and _tokenB
    function setPoolForRoute(
        address _tokenA,
        address _tokenB,
        address _pool
    ) public onlyOwner {
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(
            _tokenA,
            _tokenB,
            uint24(0) // pool fee is unused
        );
        if (_pool != address(0)) {
            require(
                poolKey.token0 == IUniswapV3Pool(_pool).token0() && poolKey.token1 == IUniswapV3Pool(_pool).token1(),
                'Tokens or pool not correct'
            );
        }
        overriddenPoolForRoute[_identifyRouteFromPoolKey(poolKey)] = _pool;
        emit PoolForRouteSet(poolKey.token0, poolKey.token1, _pool);
    }

    /// @notice Fetch the Uniswap V3 pool to be queried for a tokenA:tokenB route
    /// @param _tokenA Address of an ERC20 token contract
    /// @param _tokenB Address of another ERC20 token contract
    /// @return pool Address of a Uniswap V3 pool constructed with _tokenA and _tokenB
    function getPoolForRoute(address _tokenA, address _tokenB) public view returns (address pool) {
        return _getPoolForRoute(PoolAddress.getPoolKey(_tokenA, _tokenB, defaultPoolFee));
    }

    /**************************
     * Utility view functions *
     **************************/

    /// @notice Fetch a Uniswap V3 pool's current "spot" and TWAP tick values
    /// @param _pool Address of a Uniswap V3 pool
    /// @param _twapPeriod Number of seconds in the past to consider for the TWAP rate
    /// @return spotTick The pool's current "spot" tick
    /// @return twapTick The twap tick for the last _twapPeriod seconds
    function fetchCurrentTicks(address _pool, uint32 _twapPeriod) public view returns (int24 spotTick, int24 twapTick) {
        spotTick = OracleLibrary.getBlockStartingTick(_pool);
        twapTick = OracleLibrary.consult(_pool, _twapPeriod);
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param _tokenIn Address of an ERC20 token contract to be converted
    /// @param _amountIn Amount of tokenIn to be converted
    /// @param _tokenOut Address of an ERC20 token contract to convert into
    /// @param _tick Tick value representing conversion ratio between _tokenIn and _tokenOut
    /// @return amountOut Amount of _tokenOut received for _amountIn of _tokenIn
    function getQuoteAtTick(
        address _tokenIn,
        uint128 _amountIn,
        address _tokenOut,
        int24 _tick
    ) public pure returns (uint256 amountOut) {
        return OracleLibrary.getQuoteAtTick(_tick, _amountIn, _tokenIn, _tokenOut);
    }

    /// @notice Similar to getQuoteAtTick() but calculates the amount of token received in exchange
    ///         by first adjusting into ETH
    ///         (ie. when a route goes through an intermediary pool with ETH)
    /// @param _tokenIn Address of an ERC20 token contract to be converted
    /// @param _amountIn Amount of tokenIn to be converted
    /// @param _tokenOut Address of an ERC20 token contract to convert into
    /// @param _tick1 First tick value representing conversion ratio between _tokenIn and ETH
    /// @param _tick2 Second tick value representing conversion ratio between ETH and _tokenOut
    /// @return amountOut Amount of _tokenOut received for _amountIn of _tokenIn
    function getQuoteCrossingTicksThroughWeth(
        address _tokenIn,
        uint128 _amountIn,
        address _tokenOut,
        int24 _tick1,
        int24 _tick2
    ) public view returns (uint256 amountOut) {
        return _getQuoteCrossingTicksThroughWeth(_tokenIn, _amountIn, _tokenOut, _tick1, _tick2);
    }

    /*************
     * Internals *
     *************/

    /// @notice Given a token and amount, return the equivalent value in another token by exchanging
    ///         within a single liquidity pool
    /// @dev _pool _must_ be previously checked to contain _tokenIn and _tokenOut.
    ///      It is exposed as a parameter only as a gas optimization.
    /// @param _tokenIn Address of an ERC20 token contract to be converted
    /// @param _amountIn Amount of tokenIn to be converted
    /// @param _tokenOut Address of an ERC20 token contract to convert into
    /// @param _pool Address of a Uniswap V3 pool containing _tokenIn and _tokenOut
    /// @param _twapPeriod Number of seconds in the past to consider for the TWAP rate
    /// @return amountOut Amount of _tokenOut received for _amountIn of _tokenIn
    function _fetchAmountFromSinglePool(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        address _pool,
        uint256 _twapPeriod
    ) internal view returns (uint256 amountOut) {
        // Leave ticks as int256s to avoid solidity casting
        int256 spotTick = OracleLibrary.getBlockStartingTick(_pool);
        int256 twapTick = OracleLibrary.consult(_pool, SafeCast.toUint32(_twapPeriod));

        // Return min amount between spot price and twap
        // Ticks are based on the ratio between token0:token1 so if the input token is token1 then
        // we need to treat the tick as an inverse
        int256 minTick;
        if (_tokenIn < _tokenOut) {
            minTick = spotTick < twapTick ? spotTick : twapTick;
        } else {
            minTick = spotTick > twapTick ? spotTick : twapTick;
        }

        return
            OracleLibrary.getQuoteAtTick(
                int24(minTick), // can assume safe being result from consult()
                SafeCast.toUint128(_amountIn),
                _tokenIn,
                _tokenOut
            );
    }

    /// @notice Given a token and amount, return the equivalent value in another token by "crossing"
    ///         liquidity across an intermediary pool with ETH (ie. _tokenIn:ETH and ETH:_tokenOut)
    /// @dev If an overridden pool has been set for _tokenIn and _tokenOut, this pool will be used
    ///      used directly in lieu of "crossing" against an intermediary pool with ETH
    /// @param _tokenIn Address of an ERC20 token contract to be converted
    /// @param _amountIn Amount of tokenIn to be converted
    /// @param _tokenOut Address of an ERC20 token contract to convert into
    /// @param _twapPeriod Number of seconds in the past to consider for the TWAP rate
    /// @return amountOut Amount of _tokenOut received for _amountIn of _tokenIn
    function _fetchAmountCrossingPools(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _twapPeriod
    ) internal view returns (uint256 amountOut) {
        // If the tokenIn:tokenOut route was overridden to use a single pool, derive price directly from that pool
        address overriddenPool = _getOverriddenPool(
            PoolAddress.getPoolKey(
                _tokenIn,
                _tokenOut,
                uint24(0) // pool fee is unused
            )
        );
        if (overriddenPool != address(0)) {
            return _fetchAmountFromSinglePool(_tokenIn, _amountIn, _tokenOut, overriddenPool, _twapPeriod);
        }

        // Otherwise, derive the price by "crossing" through tokenIn:ETH -> ETH:tokenOut
        // To keep consistency, we cross through with the same price source (spot vs. twap)
        address pool1 = _getPoolForRoute(PoolAddress.getPoolKey(_tokenIn, weth, defaultPoolFee));
        address pool2 = _getPoolForRoute(PoolAddress.getPoolKey(_tokenOut, weth, defaultPoolFee));

        int24 spotTick1 = OracleLibrary.getBlockStartingTick(pool1);
        int24 spotTick2 = OracleLibrary.getBlockStartingTick(pool2);
        uint256 spotAmountOut = _getQuoteCrossingTicksThroughWeth(_tokenIn, _amountIn, _tokenOut, spotTick1, spotTick2);

        uint32 castedTwapPeriod = SafeCast.toUint32(_twapPeriod);
        int24 twapTick1 = OracleLibrary.consult(pool1, castedTwapPeriod);
        int24 twapTick2 = OracleLibrary.consult(pool2, castedTwapPeriod);
        uint256 twapAmountOut = _getQuoteCrossingTicksThroughWeth(_tokenIn, _amountIn, _tokenOut, twapTick1, twapTick2);

        // Return min amount between spot price and twap
        return spotAmountOut < twapAmountOut ? spotAmountOut : twapAmountOut;
    }

    /// @notice Similar to OracleLibrary#getQuoteAtTick but calculates the amount of token received
    ///         in exchange by first adjusting into ETH
    ///         (ie. when a route goes through an intermediary pool with ETH)
    /// @param _tokenIn Address of an ERC20 token contract to be converted
    /// @param _amountIn Amount of tokenIn to be converted
    /// @param _tokenOut Address of an ERC20 token contract to convert into
    /// @param _tick1 First tick value used to adjust from _tokenIn to ETH
    /// @param _tick2 Second tick value used to adjust from ETH to _tokenOut
    /// @return amountOut Amount of _tokenOut received for _amountIn of _tokenIn
    function _getQuoteCrossingTicksThroughWeth(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        int24 _tick1,
        int24 _tick2
    ) internal view returns (uint256 amountOut) {
        uint256 ethAmountOut = OracleLibrary.getQuoteAtTick(_tick1, SafeCast.toUint128(_amountIn), _tokenIn, weth);
        return OracleLibrary.getQuoteAtTick(_tick2, SafeCast.toUint128(ethAmountOut), weth, _tokenOut);
    }

    /// @notice Fetch the Uniswap V3 pool to be queried for a route denoted by a PoolKey
    /// @param _poolKey PoolKey representing the route
    /// @return pool Address of the Uniswap V3 pool to use for the route
    function _getPoolForRoute(PoolAddress.PoolKey memory _poolKey) internal view returns (address pool) {
        pool = _getOverriddenPool(_poolKey);
        if (pool == address(0)) {
            pool = PoolAddress.computeAddress(uniswapV3Factory, _poolKey);
        }
    }

    /// @notice Obtain the canonical identifier for a route denoted by a PoolKey
    /// @param _poolKey PoolKey representing the route
    /// @return id identifier for the route
    function _identifyRouteFromPoolKey(PoolAddress.PoolKey memory _poolKey) internal pure returns (bytes32 id) {
        return keccak256(abi.encodePacked(_poolKey.token0, _poolKey.token1));
    }

    /// @notice Fetch an overridden pool for a route denoted by a PoolKey, if any
    /// @param _poolKey PoolKey representing the route
    /// @return pool Address of the Uniswap V3 pool overridden for the route.
    ///              address(0) if no overridden pool has been set.
    function _getOverriddenPool(PoolAddress.PoolKey memory _poolKey) internal view returns (address pool) {
        return overriddenPoolForRoute[_identifyRouteFromPoolKey(_poolKey)];
    }

    /**********
     * Events *
     **********/

    event PoolForRouteSet(address indexed token0, address indexed token1, address indexed pool);
}