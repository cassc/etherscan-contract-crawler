// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./UniswapV3PoolAddress.sol";

library UniswapV3CallbackValidator {
    function validate(address poolFactory, address tokenA, address tokenB, uint24 fee) internal view {
        validate(poolFactory, UniswapV3PoolAddress.poolKey(tokenA, tokenB, fee));
    }

    function validate(address poolFactory, UniswapV3PoolAddress.PoolKey memory poolKey) internal view {
        // CV_IC: invalid caller
        require(UniswapV3PoolAddress.computeAddress(poolFactory, poolKey) == msg.sender, "CV_IC");
    }
}