// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../interfaces/IBiswapPoolV3.sol';//V3 pool
import '../interfaces/ILiquidityManager.sol';
import '../interfaces/IBiswapFactoryV3.sol';
import '../interfaces/IV3Utilities.sol';
import '../libraries/LogPowMath.sol';
import 'hardhat/console.sol';

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IOracleV2 {
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);

}

/// @title Biswap V3 Utilities contract
contract V3Utilities is IV3Utilities{
    address public constant V3FactoryAddress = 0x16Afd4b83b1F4dDc4626408fB506397FCeB4abD6;
    address public constant oracleV2Address  = 0x1c75c382E3195a0FCe4cE9def994932E0a805974;
    int24 public constant fullRangeLength    = 800000;

    function suggestBestPoolAtFactory(address factory, address token0, address token1) public view override returns(uint16 fee, address poolAddress){
        uint16[4] memory availableFees = [100, 500, 2000, 8000];
        uint tmpPseudoLiquidity;
        IERC20 _tokenX = IERC20(token0);
        IERC20 _tokenY = IERC20(token1);

        for (uint i = 0; i < availableFees.length; i++){
            address _poolAddress = IBiswapFactoryV3(factory).pool(token0, token1, availableFees[i]);
            if (_poolAddress == address(0)) continue;
            uint pseudoLiquidity = _tokenX.balanceOf(_poolAddress) + _tokenY.balanceOf(_poolAddress);

            if (pseudoLiquidity > tmpPseudoLiquidity) {
                tmpPseudoLiquidity = pseudoLiquidity;
                fee = availableFees[i];
                poolAddress = _poolAddress;
            }
        }
    }

    function suggestBestPool(address token0, address token1) public view override returns(uint16 fee, address poolAddress){
        return suggestBestPoolAtFactory(V3FactoryAddress, token0, token1);
    }

    function stretchToPD(int24 point, int24 pd) private pure returns(int24 stretchedPoint){
        if (point < -pd) return ((point / pd) * pd) + pd;
        if (point > pd) return ((point / pd) * pd);
        return 0;
    }

    function getFullRangeTicks(int24 cp, int24 pd) public pure returns(int24 pl, int24 pr){
        cp = (cp / pd) * pd;
        int24 minPoint = -800000;
        int24 maxPoint = 800000;
        
        if (cp >= fullRangeLength/2)  return (stretchToPD(maxPoint - fullRangeLength, pd), stretchToPD(maxPoint, pd));
        if (cp <= -fullRangeLength/2) return (stretchToPD(minPoint, pd),  stretchToPD(minPoint + fullRangeLength, pd));
        return (stretchToPD(cp - fullRangeLength/2, pd), stretchToPD(cp + fullRangeLength/2, pd));
    }

    function consultPool(address pool, uint32 secondsAgo) public view returns (int24 arithmeticMeanTick){
        require(secondsAgo != 0, 'BP');
        require(pool != address(0), 'V3 pool not created');

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory accPoints) = IBiswapPoolV3(pool).observe(secondsAgos);
        int56 tickCumulativesDelta = accPoints[1] - accPoints[0];
        int56 secondsAgoConverted = int56(uint56(secondsAgo));


        arithmeticMeanTick = int24(int56(tickCumulativesDelta / secondsAgoConverted));
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgoConverted != 0)) arithmeticMeanTick--;
    }

    function consultV2(address tokenIn, uint amountIn, address tokenOut) public view returns (uint amountOut) {
        amountOut = IOracleV2(oracleV2Address).consult(tokenIn, amountIn, tokenOut);
    }

    function consultV3(address tokenIn, uint amountIn, address tokenOut) public view returns (uint amountOut) {
        (, address pool) = suggestBestPool(tokenIn, tokenOut);
        if (pool == address(0)) return 0;

        int24 arithmeticMeanTick;

        try this.consultPool(pool, 5 minutes) returns (int24 arithmeticMeanTick_) {
            arithmeticMeanTick = arithmeticMeanTick_;
        } catch  {
            return 0;
        }
          
        (address token1, address token0) = sortTokens(tokenIn, tokenOut);

        uint decimals0 = IERC20(token0).decimals();
        uint decimals1 = IERC20(token1).decimals();

        if (token0 == tokenIn) {
            return computeAmountOut(arithmeticMeanTick, decimals0, decimals1, amountIn);
        } else {
            return computeAmountOut(-1 * arithmeticMeanTick, decimals1, decimals0, amountIn);
        }
    }

    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {
        uint amountOutV2 = consultV2(tokenIn, amountIn, tokenOut);
        uint amountOutV3 = consultV3(tokenIn, amountIn, tokenOut);
        return amountOutV2 > amountOutV3 ? amountOutV2 : amountOutV3;
    }

    function computeAmountOut(int24 point, uint decimalsIn, uint decimalsOut, uint amountIn) internal pure returns(uint amountOut){
        uint256 sqrtPrice96 = LogPowMath.getSqrtPrice(point);
        uint amount = amountIn * (10**decimalsOut) / (10**decimalsIn);
        return sqrtPrice96 * amount / (2**96);
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'V3Utilities: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'V3Utilities: ZERO_ADDRESS');
    }
}