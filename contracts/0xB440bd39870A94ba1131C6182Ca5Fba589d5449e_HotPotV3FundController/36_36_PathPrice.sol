// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint128.sol";
import "./FixedPoint64.sol";
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/Path.sol";

library PathPrice {
    using Path for bytes;

    /// @notice 获取目标代币当前价格的平方根
    /// @param path 兑换路径
    /// @return sqrtPriceX96 价格的平方根(X 2^96)，给定兑换路径的 tokenOut / tokenIn 的价格
    function getSqrtPriceX96(
        bytes memory path, 
        address uniV3Factory
    ) internal view returns (uint sqrtPriceX96){
        require(path.length > 0, "IPL");

        sqrtPriceX96 = FixedPoint96.Q96;
        uint _nextSqrtPriceX96;
        uint32[] memory secondAges = new uint32[](2);
        secondAges[0] = 0;
        secondAges[1] = 1;
        while (true) {
            (address tokenIn, address tokenOut, uint24 fee) = path.decodeFirstPool();
            IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(uniV3Factory, PoolAddress.getPoolKey(tokenIn, tokenOut, fee)));

            (_nextSqrtPriceX96,,,,,,) = pool.slot0();
            sqrtPriceX96 = tokenIn > tokenOut
                ? FullMath.mulDiv(sqrtPriceX96, FixedPoint96.Q96, _nextSqrtPriceX96)
                : FullMath.mulDiv(sqrtPriceX96, _nextSqrtPriceX96, FixedPoint96.Q96);

            // decide whether to continue or terminate
            if (path.hasMultiplePools())
                path = path.skipToken();
            else 
                break; 
        }
    }

    /// @notice 获取目标代币预言机价格的平方根
    /// @param path 兑换路径
    /// @return sqrtPriceX96Last 预言机价格的平方根(X 2^96)，给定兑换路径的 tokenOut / tokenIn 的价格
    function getSqrtPriceX96Last(
        bytes memory path, 
        address uniV3Factory
    ) internal view returns (uint sqrtPriceX96Last){
        require(path.length > 0, "IPL");

        sqrtPriceX96Last = FixedPoint96.Q96;
        uint _nextSqrtPriceX96;
        uint32[] memory secondAges = new uint32[](2);
        secondAges[0] = 0;
        secondAges[1] = 1;
        while (true) {
            (address tokenIn, address tokenOut, uint24 fee) = path.decodeFirstPool();
            IUniswapV3Pool pool = IUniswapV3Pool(PoolAddress.computeAddress(uniV3Factory, PoolAddress.getPoolKey(tokenIn, tokenOut, fee)));

            // sqrtPriceX96Last
            (int56[] memory tickCumulatives,) = pool.observe(secondAges);
            _nextSqrtPriceX96 = TickMath.getSqrtRatioAtTick(int24(tickCumulatives[0] - tickCumulatives[1]));
            sqrtPriceX96Last = tokenIn > tokenOut
                ? FullMath.mulDiv(sqrtPriceX96Last, FixedPoint96.Q96, _nextSqrtPriceX96)
                : FullMath.mulDiv(sqrtPriceX96Last, _nextSqrtPriceX96, FixedPoint96.Q96);

            // decide whether to continue or terminate
            if (path.hasMultiplePools())
                path = path.skipToken();
            else 
                break;
        }
    }

    /// @notice 验证交易滑点是否满足条件
    /// @param path 兑换路径
    /// @param uniV3Factory uniswap v3 factory
    /// @param maxSqrtSlippage 最大滑点,最大值: 1e4
    /// @return 当前价
    function verifySlippage(
        bytes memory path, 
        address uniV3Factory, 
        uint32 maxSqrtSlippage
    ) internal view returns(uint) { 
        uint last = getSqrtPriceX96Last(path, uniV3Factory);
        uint current = getSqrtPriceX96(path, uniV3Factory);
        if(last > current) require(current > FullMath.mulDiv(maxSqrtSlippage, last, 1e4), "VS");
        return current;
    }
}