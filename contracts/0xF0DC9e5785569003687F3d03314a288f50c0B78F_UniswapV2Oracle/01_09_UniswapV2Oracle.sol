pragma solidity ^0.8.4;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "./libs/UniswapV2OracleLibrary.sol";
import "./libs/UniswapV2Library.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract UniswapV2Oracle {
    using FixedPoint for *;

    uint256 public constant PERIOD = 3 days;

    IUniswapV2Pair immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    constructor(
        IUniswapV2Pair _pair
    ) {
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "NO_RESERVES"); // ensure that there's liquidity in the pair
    }

    function update() external {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        require(timeElapsed >= PERIOD, "PERIOD_NOT_ELAPSED");

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(
            uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)
        );
        price1Average = FixedPoint.uq112x112(
            uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)
        );

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    function consultAndUpdateIfNecessary(address token, uint256 amountIn)
        external
        returns (uint256)
    {
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        //saves gas if timeElapsed >= PERIOD
        FixedPoint.uq112x112 memory price0Avg;
        FixedPoint.uq112x112 memory price1Avg;

        if (timeElapsed >= PERIOD) {
            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            price0Avg = FixedPoint.uq112x112(
                uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)
            );
            price1Avg = FixedPoint.uq112x112(
                uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)
            );

            price0Average = price0Avg;
            price1Average = price1Avg;

            price0CumulativeLast = price0Cumulative;
            price1CumulativeLast = price1Cumulative;
            blockTimestampLast = blockTimestamp;
        } else {
            price0Avg = price0Average;
            price1Avg = price1Average;
        }

        if (token == token0) return price0Avg.mul(amountIn).decode144();
        else {
            require(token == token1, "INVALID_TOKEN");
            return price0Avg.mul(amountIn).decode144();
        }
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, "INVALID_TOKEN");
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }

    function consultUpdated(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        if (blockTimestampLast == 0) return 0;

        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        FixedPoint.uq112x112 memory priceAvg;

        if (timeElapsed >= PERIOD) {
            if (token == token0)
                priceAvg = FixedPoint.uq112x112(
                    uint224(
                        (price0Cumulative - price0CumulativeLast) / timeElapsed
                    )
                );
            else {
                require(token == token1, "INVALID_TOKEN");
                priceAvg = FixedPoint.uq112x112(
                    uint224(
                        (price1Cumulative - price1CumulativeLast) / timeElapsed
                    )
                );
            }
        } else {
            if (token == token0)
                priceAvg = price0Average;
            else {
                require(token == token1, "INVALID_TOKEN");     
                priceAvg = price1Average;
            }
        }

        return priceAvg.mul(amountIn).decode144();
    }
}