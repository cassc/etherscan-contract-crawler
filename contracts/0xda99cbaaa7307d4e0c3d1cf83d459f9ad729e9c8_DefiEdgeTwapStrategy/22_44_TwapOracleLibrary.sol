//SPDX-License-Identifier: BSL
pragma solidity 0.7.6;
pragma abicoder v2;

// contracts
import "@chainlink/contracts/src/v0.7/Denominations.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

// libraries
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "../../libraries/CommonMath.sol";

// interfaces
import "@chainlink/contracts/src/v0.7/interfaces/FeedRegistryInterface.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../interfaces/ITwapStrategyFactory.sol";
import "../interfaces/ITwapStrategyManager.sol";
import "../../interfaces/IERC20Minimal.sol";

library TwapOracleLibrary {
    uint256 public constant BASE = 1e18;

    using SafeMath for uint256;

    function normalise(address _token, uint256 _amount) internal view returns (uint256 normalised) {
        // return uint256(_amount) * (10**(18 - IERC20Minimal(_token).decimals()));
        normalised = _amount;
        uint256 _decimals = IERC20Minimal(_token).decimals();

        if (_decimals < 18) {
            uint256 missingDecimals = uint256(18).sub(_decimals);
            normalised = uint256(_amount).mul(10**(missingDecimals));
        } else if (_decimals > 18) {
            uint256 extraDecimals = _decimals.sub(uint256(18));
            normalised = uint256(_amount).div(10**(extraDecimals));
        }
    }

    /**
     * @notice Gets latest Uniswap price in the pool, price of token0 represented in token1
     * @notice _pool Address of the Uniswap V3 pool
     */
    function getUniswapPrice(IUniswapV3Pool _pool) internal view returns (uint256 price) {
        (uint160 sqrtPriceX96, , , , , , ) = _pool.slot0();
        uint256 priceX192 = uint256(sqrtPriceX96).mul(sqrtPriceX96);
        price = FullMath.mulDiv(priceX192, BASE, 1 << 192);

        uint256 token0Decimals = IERC20Minimal(_pool.token0()).decimals();
        uint256 token1Decimals = IERC20Minimal(_pool.token1()).decimals();

        bool decimalCheck = token0Decimals > token1Decimals;

        uint256 decimalsDelta = decimalCheck ? token0Decimals - token1Decimals : token1Decimals - token0Decimals;

        // normalise the price to 18 decimals

        if (token0Decimals == token1Decimals) {
            return price;
        }

        if (decimalCheck) {
            price = price.mul(CommonMath.safePower(10, decimalsDelta));
        } else {
            price = price.div(CommonMath.safePower(10, decimalsDelta));
        }
    }

    /**
     * @notice Returns latest Chainlink price, and normalise it
     * @param _registry registry
     * @param _base Base Asset
     * @param _quote Quote Asset
     */
    function getChainlinkPrice(
        FeedRegistryInterface _registry,
        address _base,
        address _quote,
        uint256 _validPeriod
    ) internal view returns (uint256 price) {
        (, int256 _price, , uint256 updatedAt, ) = _registry.latestRoundData(_base, _quote);

        require(block.timestamp.sub(updatedAt) < _validPeriod, "OLD_PRICE");

        if (_price <= 0) {
            return 0;
        }

        // normalise the price to 18 decimals
        uint256 _decimals = _registry.decimals(_base, _quote);

        if (_decimals < 18) {
            uint256 missingDecimals = uint256(18).sub(_decimals);
            price = uint256(_price).mul(10**(missingDecimals));
        } else if (_decimals > 18) {
            uint256 extraDecimals = _decimals.sub(uint256(18));
            price = uint256(_price).div(10**(extraDecimals));
        }

        return price;
    }

    /**
     * @notice Gets latest Uniswap price in the pool, price of _token represented in USD
     * @param _pool Address of the Uniswap V3 pool
     * @param _registry Interface of the Chainlink registry
     * @param _priceOf the token we want to convert into USD
     * @param _useTwap tif the contract should use uniswap v3 twap to fetch usd price of chainlink
     */
    function getPriceInUSD(
        ITwapStrategyFactory _factory,
        IUniswapV3Pool _pool,
        FeedRegistryInterface _registry,
        address _priceOf,
        bool[2] memory _useTwap,
        ITwapStrategyManager _manager
    ) internal view returns (uint256 price) {
        uint256 _period = _manager.twapPricePeriod();

        if (_useTwap[0]) {
            address _token1 = _pool.token1();
            // token0 - twap , token1 - chainlink
            uint256 token1ChainlinkPrice = getChainlinkPrice(
                _registry,
                _token1,
                Denominations.USD,
                _factory.getHeartBeat(_token1, Denominations.USD)
            );

            if (_priceOf == _token1) {
                price = token1ChainlinkPrice;
            } else {
                // price of token0 denominated in token1
                uint256 _price = consult(address(_pool), uint32(_period));
                price = _price.mul(token1ChainlinkPrice).div(BASE);
            }
        } else {
            address _token0 = _pool.token0();
            // // token0 - chainlink , token1 - twap
            uint256 token0ChainlinkPrice = getChainlinkPrice(
                _registry,
                _token0,
                Denominations.USD,
                _factory.getHeartBeat(_token0, Denominations.USD)
            );

            if (_priceOf == _token0) {
                price = token0ChainlinkPrice;
            } else {
                // price of token0 denominated in token1
                uint256 _price = consult(address(_pool), uint32(_period));
                _price = 1e36 / _price;
                price = _price.mul(token0ChainlinkPrice).div(BASE);
            }
        }
    }

    /**
     * @notice Checks for price slippage at the time of swap
     * @param _pool Address of the pool
     * @param _factory Address of the DefiEdge strategy factory
     * @param _amountIn Amount to be swapped
     * @param _amountOut Amount received after swap
     * @param _tokenIn Token to be swapped
     * @param _tokenOut Token to which tokenIn should be swapped
     * @return true if the swap is allowed, else false
     */
    function allowSwap(
        IUniswapV3Pool _pool,
        ITwapStrategyFactory _factory,
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        ITwapStrategyManager _manager,
        bool[2] memory _useTwap
    ) public view returns (bool) {
        _amountIn = normalise(_tokenIn, _amountIn);
        _amountOut = normalise(_tokenOut, _amountOut);

        // get price of token0 Uniswap and convert it to USD
        uint256 amountInUSD = _amountIn.mul(
            getPriceInUSD(_factory, _pool, FeedRegistryInterface(_factory.chainlinkRegistry()), _tokenIn, _useTwap, _manager)
        );

        // get price of token0 Uniswap and convert it to USD
        uint256 amountOutUSD = _amountOut.mul(
            getPriceInUSD(_factory, _pool, FeedRegistryInterface(_factory.chainlinkRegistry()), _tokenOut, _useTwap, _manager)
        );

        uint256 diff;

        diff = amountInUSD.div(amountOutUSD.div(BASE));

        uint256 _allowedSlippage = _factory.allowedSlippage(address(_pool));
        // check if the price is above deviation
        if (diff > (BASE.add(_allowedSlippage)) || diff < (BASE.sub(_allowedSlippage))) {
            return false;
        }

        return true;
    }

    /**
     * @notice Gets time weighted tick to calculate price
     * @param _pool Address of the pool
     * @param _period Seconds to query data from
     */
    function getTick(address _pool, uint32 _period) internal view returns (int24 timeWeightedAverageTick) {
        require(_period != 0, "BP");

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = _period;
        secondAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(_pool).observe(secondAgos);
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        timeWeightedAverageTick = int24(tickCumulativesDelta / _period);

        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % _period != 0)) timeWeightedAverageTick--;
    }

    /**
     * @notice Consults V3 TWAP oracle
     * @param _pool Address of the pool
     * @param _period Seconds from which the data needs to be queried
     * @return price Price of the assets calculated from Uniswap V3 Oracle
     */
    function consult(address _pool, uint32 _period) internal view returns (uint256 price) {
        int24 tick = getTick(_pool, _period);

        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate price with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96).mul(sqrtRatioX96);
            price = FullMath.mulDiv(ratioX192, BASE, 1 << 192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            price = FullMath.mulDiv(ratioX128, BASE, 1 << 128);
        }

        uint256 token0Decimals = IERC20Minimal(IUniswapV3Pool(_pool).token0()).decimals();
        uint256 token1Decimals = IERC20Minimal(IUniswapV3Pool(_pool).token1()).decimals();

        bool decimalCheck = token0Decimals > token1Decimals;

        uint256 decimalsDelta = decimalCheck ? token0Decimals - token1Decimals : token1Decimals - token0Decimals;

        // normalise the price to 18 decimals
        if (token0Decimals == token1Decimals) {
            return price;
        }

        if (decimalCheck) {
            price = price.mul(CommonMath.safePower(10, decimalsDelta));
        } else {
            price = price.div(CommonMath.safePower(10, decimalsDelta));
        }
    }
}