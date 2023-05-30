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
import "./CommonMath.sol";

// interfaces
import "@chainlink/contracts/src/v0.7/interfaces/FeedRegistryInterface.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../interfaces/IStrategyFactory.sol";
import "../interfaces/IStrategyManager.sol";
import "../interfaces/IERC20Minimal.sol";

library OracleLibrary {
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
     * @notice Gets latest Uniswap price in the pool, price of token1 represented in token0
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
     * @notice Gets price in USD, if USD feed is not available use ETH feed
     * @param _registry Interface of the Chainlink registry
     * @param _token the token we want to convert into USD
     * @param _isBase if the token supports base as USD or requires conversion from ETH
     */
    function getPriceInUSD(
        IStrategyFactory _factory,
        FeedRegistryInterface _registry,
        address _token,
        bool _isBase
    ) internal view returns (uint256 price) {
        if (_isBase) {
            price = getChainlinkPrice(_registry, _token, Denominations.USD, _factory.getHeartBeat(_token, Denominations.USD));
        } else {
            price = getChainlinkPrice(_registry, _token, Denominations.ETH, _factory.getHeartBeat(_token, Denominations.ETH));

            price = FullMath.mulDiv(
                price,
                getChainlinkPrice(
                    _registry,
                    Denominations.ETH,
                    Denominations.USD,
                    _factory.getHeartBeat(Denominations.ETH, Denominations.USD)
                ),
                BASE
            );
        }
    }

    /**
     * @notice Checks if the the current price has deviation from the pool price
     * @param _pool Address of the pool
     * @param _registry Chainlink registry interface
     * @param _usdAsBase checks if pegged to USD
     * @param _manager Manager contract address to check allowed deviation
     */
    function hasDeviation(
        IStrategyFactory _factory,
        IUniswapV3Pool _pool,
        FeedRegistryInterface _registry,
        bool[2] memory _usdAsBase,
        address _manager
    ) public view returns (bool) {
        // get price of token0 Uniswap and convert it to USD
        uint256 uniswapPriceInUSD = FullMath.mulDiv(
            getUniswapPrice(_pool),
            getPriceInUSD(_factory, _registry, _pool.token1(), _usdAsBase[1]),
            BASE
        );

        // get price of token0 from Chainlink in USD
        uint256 chainlinkPriceInUSD = getPriceInUSD(_factory, _registry, _pool.token0(), _usdAsBase[0]);

        uint256 diff;

        diff = FullMath.mulDiv(uniswapPriceInUSD, BASE, chainlinkPriceInUSD);

        uint256 _allowedDeviation = IStrategyManager(_manager).allowedDeviation();

        // check if the price is above deviation and return
        return diff > BASE.add(_allowedDeviation) || diff < BASE.sub(_allowedDeviation);
    }

    // /**
    //  * @notice Checks the if swap exceed allowed swap deviation or not
    //  * @param _pool Address of the pool
    //  * @param _registry Chainlink registry interface
    //  * @param _amountIn Amount to be swapped
    //  * @param _amountOut Amount received after swap
    //  * @param _tokenIn Token to be swapped
    //  * @param _tokenOut Token to which tokenIn should be swapped
    //  * @param _usdAsBase checks if pegged to USD
    //  * @param _manager Manager contract address to check allowed deviation
    //  */
    // function isSwapExceedDeviation(
    //     IStrategyFactory _factory,
    //     IUniswapV3Pool _pool,
    //     FeedRegistryInterface _registry,
    //     uint256 _amountIn,
    //     uint256 _amountOut,
    //     address _tokenIn,
    //     address _tokenOut,
    //     bool[2] memory _usdAsBase,
    //     address _manager
    // ) public view returns (bool) {
    //     _amountIn = normalise(_tokenIn, _amountIn);
    //     _amountOut = normalise(_tokenOut, _amountOut);

    //     (bool usdAsBaseAmountIn, bool usdAsBaseAmountOut) = _pool.token0() == _tokenIn
    //         ? (_usdAsBase[0], _usdAsBase[1])
    //         : (_usdAsBase[1], _usdAsBase[0]);

    //     // get tokenIn prce in USD fron chainlink
    //     uint256 amountInUSD = _amountIn.mul(getPriceInUSD(_factory, _registry, _tokenIn, usdAsBaseAmountIn));

    //     // get tokenout prce in USD fron chainlink
    //     uint256 amountOutUSD = _amountOut.mul(getPriceInUSD(_factory, _registry, _tokenOut, usdAsBaseAmountOut));

    //     uint256 diff;

    //     diff = amountInUSD.div(amountOutUSD.div(BASE));

    //     // check price deviation
    //     uint256 deviation;
    //     if (diff > BASE) {
    //         deviation = diff.sub(BASE);
    //     } else {
    //         deviation = BASE.sub(diff);
    //     }

    //     if (deviation > IStrategyManager(_manager).allowedSwapDeviation()) {
    //         return true;
    //     }
    //     return false;
    // }

    /**
     * @notice Checks for price slippage at the time of swap
     * @param _pool Address of the pool
     * @param _factory Address of the DefiEdge strategy factory
     * @param _amountIn Amount to be swapped
     * @param _amountOut Amount received after swap
     * @param _tokenIn Token to be swapped
     * @param _tokenOut Token to which tokenIn should be swapped
     * @param _isBase to take token as bas etoken or not
     * @return true if the swap is allowed, else false
     */
    function allowSwap(
        IUniswapV3Pool _pool,
        IStrategyFactory _factory,
        uint256 _amountIn,
        uint256 _amountOut,
        address _tokenIn,
        address _tokenOut,
        bool[2] memory _isBase
    ) public view returns (bool) {
        _amountIn = normalise(_tokenIn, _amountIn);
        _amountOut = normalise(_tokenOut, _amountOut);

        (bool usdAsBaseAmountIn, bool usdAsBaseAmountOut) = _pool.token0() == _tokenIn
            ? (_isBase[0], _isBase[1])
            : (_isBase[1], _isBase[0]);

        // get price of token0 Uniswap and convert it to USD
        uint256 amountInUSD = _amountIn.mul(
            getPriceInUSD(_factory, FeedRegistryInterface(_factory.chainlinkRegistry()), _tokenIn, usdAsBaseAmountIn)
        );

        // get price of token0 Uniswap and convert it to USD
        uint256 amountOutUSD = _amountOut.mul(
            getPriceInUSD(_factory, FeedRegistryInterface(_factory.chainlinkRegistry()), _tokenOut, usdAsBaseAmountOut)
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
}