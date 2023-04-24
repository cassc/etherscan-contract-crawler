// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {IWETH9} from "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";

library UniswapLiquidity {
    IWETH9 public constant WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    INonfungiblePositionManager public constant V3_LP_MANAGER = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    // Since V3 Factory doesnt have this as a getter
    function feeAmountTickSpacing(uint24 feeTier) internal pure returns (int24) {
        if (feeTier == 500) return 10;
        if (feeTier == 3000) return 60;
        if (feeTier == 10000) return 200;
        return 0;
    }

    function orderTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB);
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function maxTickBoundary(uint24 feeTier) internal pure returns (int24 lowerTick, int24 upperTick) {
        int24 tickSpacing = feeAmountTickSpacing(feeTier);
        require(tickSpacing != 0, "Not a valid feeTier");
        int24 feeTickCorrection = (TickMath.MAX_TICK % tickSpacing);
        (lowerTick, upperTick) = (TickMath.MIN_TICK + feeTickCorrection, TickMath.MAX_TICK - feeTickCorrection);
    }

    function normalizeAmounts(uint256 token0Amount, uint256 token1Amount, uint8 token0Decimals, uint8 token1Decimals) internal pure returns (uint256 normToken0Amount, uint256 normToken1Amount) {
        if (token0Decimals > token1Decimals) {
            uint256 multiplier = 10 ** (token0Decimals - token1Decimals);
            normToken0Amount = token0Amount;
            normToken1Amount = token1Amount * multiplier;
        } else if (token0Decimals < token1Decimals) {
            uint256 multiplier = 10 ** (token1Decimals - token0Decimals);
            normToken0Amount = token0Amount * multiplier;
            normToken1Amount = token1Amount;
        } else {
            normToken0Amount = token0Amount;
            normToken1Amount = token1Amount;
        }
    }

    function sqrtPriceX96FromAmounts(uint256 token0Amount, uint256 token1Amount) internal pure returns (uint160 result) {
        unchecked {
            result = uint160(_sqrt((token1Amount * 2 ** 192) / token0Amount));
        }
    }

    function _sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

}