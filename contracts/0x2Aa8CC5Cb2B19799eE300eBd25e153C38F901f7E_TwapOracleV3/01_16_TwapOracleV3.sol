// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import './interfaces/ITwapOracleV3.sol';
import './interfaces/IERC20.sol';
import './libraries/SafeMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';

contract TwapOracleV3 is ITwapOracleV3 {
    using SafeMath for uint256;
    using SafeMath for int256;

    uint256 private constant PRECISION = 10**18;

    uint8 public immutable override xDecimals;
    uint8 public immutable override yDecimals;
    uint32 public twapInterval;
    int256 public immutable override decimalsConverter;
    address public override owner;
    address public override uniswapPair;

    constructor(uint8 _xDecimals, uint8 _yDecimals) {
        require(_xDecimals <= 75 && _yDecimals <= 75, 'TO4F');
        if (_yDecimals > _xDecimals) {
            require(_yDecimals - _xDecimals <= 18, 'TO47');
        } else {
            require(_xDecimals - _yDecimals <= 18, 'TO47');
        }
        owner = msg.sender;
        xDecimals = _xDecimals;
        yDecimals = _yDecimals;
        decimalsConverter = (10**(18 + _xDecimals - _yDecimals)).toInt256();

        emit OwnerSet(msg.sender);
    }

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'TO00');
        require(_owner != address(0), 'TO02');
        require(_owner != owner, 'TO01');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    function setTwapInterval(uint32 _interval) external override {
        require(msg.sender == owner, 'TO00');
        require(_interval > 0, 'Interval should be larger than 0');
        twapInterval = _interval;
        emit TwapIntervalSet(_interval);
    }

    function setUniswapPair(address _uniswapPair) external override {
        require(msg.sender == owner, 'TO00');
        require(_uniswapPair != uniswapPair, 'TO01');
        require(_uniswapPair != address(0), 'TO02');
        require(isContract(_uniswapPair), 'TO0B');
        uniswapPair = _uniswapPair;

        IUniswapV3Pool pool = IUniswapV3Pool(_uniswapPair);
        require(IERC20(pool.token0()).decimals() == xDecimals && IERC20(pool.token1()).decimals() == yDecimals, 'TO45');

        require(pool.liquidity() != 0, 'TO1F');
        emit UniswapPairSet(_uniswapPair);
    }

    function getPriceInfo() public view override returns (uint256 priceAccumulator, uint32 priceTimestamp) {
        return (0, uint32(block.timestamp));
    }

    function decodePriceInfo(bytes memory data) internal pure returns (uint256 price) {
        assembly {
            price := mload(add(data, 32))
        }
    }

    function getSpotPrice() external view override returns (uint256) {
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapPair).slot0();

        if (sqrtPriceX96 <= type(uint128).max) {
            uint256 priceX192 = uint256(sqrtPriceX96) * sqrtPriceX96;
            return FullMath.mulDiv(priceX192, uint256(decimalsConverter), 2**192);
        } else {
            uint256 priceX128 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 2**64);
            return FullMath.mulDiv(priceX128, uint256(decimalsConverter), 2**128);
        }
    }

    function getAveragePrice(uint256, uint32) public view override returns (uint256) {
        uint32 secondsAgo = twapInterval;
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapPair).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 arithmeticMeanTick = int24(tickCumulativesDelta / secondsAgo);
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) --arithmeticMeanTick;

        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);

        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            return FullMath.mulDiv(ratioX192, uint256(decimalsConverter), 2**192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 2**64);
            return FullMath.mulDiv(ratioX128, uint256(decimalsConverter), 2**128);
        }
    }

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256 yAfter) {
        int256 xAfterInt = xAfter.toInt256();
        int256 xBeforeInt = xBefore.toInt256();
        int256 yBeforeInt = yBefore.toInt256();
        int256 averagePriceInt = decodePriceInfo(data).toInt256();

        int256 yTradedInt = xAfterInt.sub(xBeforeInt).mul(averagePriceInt);

        // yAfter = yBefore - yTraded = yBefore - ((xAfter - xBefore) * price)
        int256 yAfterInt = yBeforeInt.sub(yTradedInt.neg_floor_div(decimalsConverter));
        require(yAfterInt >= 0, 'TO27');

        yAfter = uint256(yAfterInt);
    }

    function tradeY(
        uint256 yAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256 xAfter) {
        int256 yAfterInt = yAfter.toInt256();
        int256 xBeforeInt = xBefore.toInt256();
        int256 yBeforeInt = yBefore.toInt256();
        int256 averagePriceInt = decodePriceInfo(data).toInt256();

        int256 xTradedInt = yAfterInt.sub(yBeforeInt).mul(decimalsConverter);

        // xAfter = xBefore - xTraded = xBefore - ((yAfter - yBefore) * price)
        int256 xAfterInt = xBeforeInt.sub(xTradedInt.neg_floor_div(averagePriceInt));
        require(xAfterInt >= 0, 'TO28');

        xAfter = uint256(xAfterInt);
    }

    function depositTradeXIn(
        uint256 xLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256) {
        if (xBefore == 0 || yBefore == 0) {
            return 0;
        }

        // ratio after swap = ratio after second mint
        // (xBefore + xIn) / (yBefore - xIn * price) = (xBefore + xLeft) / yBefore
        // xIn = xLeft * yBefore / (price * (xLeft + xBefore) + yBefore)
        uint256 price = decodePriceInfo(data);
        uint256 numerator = xLeft.mul(yBefore);
        uint256 denominator = price.mul(xLeft.add(xBefore)).add(yBefore.mul(uint256(decimalsConverter)));
        uint256 xIn = numerator.mul(uint256(decimalsConverter)).div(denominator);

        // Don't swap when numbers are too large. This should actually never happen.
        if (xIn.mul(price).div(uint256(decimalsConverter)) >= yBefore || xIn >= xLeft) {
            return 0;
        }

        return xIn;
    }

    function depositTradeYIn(
        uint256 yLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view override returns (uint256) {
        if (xBefore == 0 || yBefore == 0) {
            return 0;
        }

        // ratio after swap = ratio after second mint
        // (xBefore - yIn / price) / (yBefore + yIn) = xBefore / (yBefore + yLeft)
        // yIn = price * xBefore * yLeft / (price * xBefore + yLeft + yBefore)
        uint256 price = decodePriceInfo(data);
        uint256 numerator = price.mul(xBefore).mul(yLeft);
        uint256 denominator = price.mul(xBefore).add(yLeft.add(yBefore).mul(uint256(decimalsConverter)));
        uint256 yIn = numerator.div(denominator);

        // Don't swap when numbers are too large. This should actually never happen.
        if (yIn.mul(uint256(decimalsConverter)).div(price) >= xBefore || yIn >= yLeft) {
            return 0;
        }

        return yIn;
    }

    function getSwapAmount0Out(
        uint256 swapFee,
        uint256 amount1In,
        bytes calldata data
    ) public view override returns (uint256 amount0Out) {
        uint256 fee = amount1In.mul(swapFee).div(PRECISION);
        uint256 price = decodePriceInfo(data);
        amount0Out = amount1In.sub(fee).mul(uint256(decimalsConverter)).div(price);
    }

    function getSwapAmount1Out(
        uint256 swapFee,
        uint256 amount0In,
        bytes calldata data
    ) public view override returns (uint256 amount1Out) {
        uint256 fee = amount0In.mul(swapFee).div(PRECISION);
        uint256 price = decodePriceInfo(data);
        amount1Out = amount0In.sub(fee).mul(price).div(uint256(decimalsConverter));
    }

    function getSwapAmount0InMax(
        uint256 swapFee,
        uint256 amount1Out,
        bytes calldata data
    ) internal view returns (uint256 amount0In) {
        uint256 price = decodePriceInfo(data);
        amount0In = amount1Out.mul(uint256(decimalsConverter)).mul(PRECISION).ceil_div(
            price.mul(PRECISION.sub(swapFee))
        );
    }

    function getSwapAmount0InMin(
        uint256 swapFee,
        uint256 amount1Out,
        bytes calldata data
    ) internal view returns (uint256 amount0In) {
        uint256 price = decodePriceInfo(data);
        amount0In = amount1Out.mul(uint256(decimalsConverter)).div(price).mul(PRECISION).div(PRECISION.sub(swapFee));
    }

    function getSwapAmount1InMax(
        uint256 swapFee,
        uint256 amount0Out,
        bytes calldata data
    ) internal view returns (uint256 amount1In) {
        uint256 price = decodePriceInfo(data);
        amount1In = amount0Out.mul(price).mul(PRECISION).ceil_div(
            uint256(decimalsConverter).mul(PRECISION.sub(swapFee))
        );
    }

    function getSwapAmount1InMin(
        uint256 swapFee,
        uint256 amount0Out,
        bytes calldata data
    ) internal view returns (uint256 amount1In) {
        uint256 price = decodePriceInfo(data);
        amount1In = amount0Out.mul(price).div(uint256(decimalsConverter)).mul(PRECISION).div(PRECISION.sub(swapFee));
    }

    function getSwapAmountInMaxOut(
        bool inverse,
        uint256 swapFee,
        uint256 _amountOut,
        bytes calldata data
    ) external view override returns (uint256 amountIn, uint256 amountOut) {
        amountIn = inverse
            ? getSwapAmount1InMax(swapFee, _amountOut, data)
            : getSwapAmount0InMax(swapFee, _amountOut, data);
        amountOut = inverse ? getSwapAmount0Out(swapFee, amountIn, data) : getSwapAmount1Out(swapFee, amountIn, data);
    }

    function getSwapAmountInMinOut(
        bool inverse,
        uint256 swapFee,
        uint256 _amountOut,
        bytes calldata data
    ) external view override returns (uint256 amountIn, uint256 amountOut) {
        amountIn = inverse
            ? getSwapAmount1InMin(swapFee, _amountOut, data)
            : getSwapAmount0InMin(swapFee, _amountOut, data);
        amountOut = inverse ? getSwapAmount0Out(swapFee, amountIn, data) : getSwapAmount1Out(swapFee, amountIn, data);
    }
}