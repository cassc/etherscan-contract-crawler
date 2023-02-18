// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IUniswapV3PoolDerivedState} from "../dependencies/uniswap/IUniswapV3PoolDerivedState.sol";
import {IUniswapV3PoolState} from "../dependencies/uniswap/IUniswapV3PoolState.sol";
import {SafeCast} from "../dependencies/univ3/libraries/SafeCast.sol";
import {ICLSynchronicityPriceAdapter} from "../dependencies/chainlink/ICLSynchronicityPriceAdapter.sol";
import {TickMath} from "../dependencies/uniswap/libraries/TickMath.sol";
import {FullMath} from "../dependencies/uniswap/libraries/FullMath.sol";
import {FixedPoint96} from "../dependencies/univ3/libraries/FixedPoint96.sol";
import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";

contract UniswapV3TwapOracleWrapper is ICLSynchronicityPriceAdapter {
    using SafeCast for uint256;

    address immutable UNISWAP_V3_POOL;
    int32 immutable TWAP_WINDOW;
    address immutable ASSET;
    bool immutable IS_ASSET_RESERVE_ZERO;
    uint256 public immutable MANTISSA;

    constructor(
        address _pool,
        address _baseCurrency,
        int32 twapWindow
    ) {
        UNISWAP_V3_POOL = _pool;
        TWAP_WINDOW = twapWindow;

        address token0 = IUniswapV3PoolState(_pool).token0();
        address token1 = IUniswapV3PoolState(_pool).token1();
        IS_ASSET_RESERVE_ZERO = token0 != _baseCurrency;
        ASSET = IS_ASSET_RESERVE_ZERO ? token0 : token1;

        MANTISSA =
            10 **
                (IERC20Detailed(token0).decimals() +
                    18 -
                    IERC20Detailed(token1).decimals());
    }

    function latestAnswer() external view returns (int256) {
        uint256 priceX96 = _getTwapPriceX96(UNISWAP_V3_POOL, TWAP_WINDOW);
        // priceX96 = (amount1 / amount0) << 96
        // price = price0 / price1 = (amount1 / amount0) * (decimal0 / decimal1)
        uint256 price = FullMath.mulDiv(priceX96, MANTISSA, FixedPoint96.Q96);
        if (IS_ASSET_RESERVE_ZERO) {
            return price.toInt256();
        } else {
            // price = price0 / price1 * 1e18
            // price_reciprocal  = price1 / price0 * 1e18 =  1e36 / price
            return (1E36 / price).toInt256();
        }
    }

    function _getTwapPriceX96(address pool, int32 twapWindow)
        internal
        view
        returns (uint256)
    {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = uint32(twapWindow);
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3PoolDerivedState(pool)
            .observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        int24 arithmeticMeanTick = int24(tickCumulativesDelta / twapWindow);
        // Always round to negative infinity to make sqrtPriceX96 smaller
        // -1111 / 20 = -55 will be round down to -56
        if (
            tickCumulativesDelta < 0 && (tickCumulativesDelta % twapWindow != 0)
        ) arithmeticMeanTick--;

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);

        // sqrtPriceX96 = sqrt(priceX96 >> 96) << 96
        // priceX96 = sqrtPriceX96 * sqrtPriceX96  >> 96
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }
}