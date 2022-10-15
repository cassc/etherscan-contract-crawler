//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PoolAddress.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../constants/Constants.sol";

library UniswapV3Library {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (IUniswapV3Pool) {
        return
            IUniswapV3Pool(
                PoolAddress.computeAddress(
                    Constants.UNISWAP_V3_FACTORY,
                    PoolAddress.getPoolKey(tokenA, tokenB, fee)
                )
            );
    }
}