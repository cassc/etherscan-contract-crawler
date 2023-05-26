// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "../interfaces/IUniswapV2Pair.sol";

library OneInchSwapValidation {
    function getOutputTokenForInputTokenAndPair(address tokenIn, address pair)
        internal
        view
        returns (address)
    {
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        if (token0 == tokenIn) {
            return token1;
        }
        if (token1 == tokenIn) {
            return token0;
        }
        revert("ERR_TOKEN_MISSING_IN_PAIR");
    }

    function validateUnoswap(
        address tokenIn,
        address tokenOut,
        bytes32[] calldata pools
    ) internal view {
        address outputToken = tokenIn;
        for (uint8 i = 0; i < pools.length; i++) {
            outputToken = getOutputTokenForInputTokenAndPair(
                outputToken,
                address(uint160(uint256(pools[i])))
            );
        }
        require(outputToken == tokenOut, "ERR_OUTPUT_TOKEN");
    }

    function validateUniswapV3Swap(
        address tokenIn,
        address tokenOut,
        uint256[] calldata pools
    ) internal view {
        address outputToken = tokenIn;
        for (uint8 i = 0; i < pools.length; i++) {
            outputToken = getOutputTokenForInputTokenAndPair(
                outputToken,
                address(uint160(pools[i]))
            );
        }
        require(outputToken == tokenOut, "ERR_OUTPUT_TOKEN");
    }

    
}