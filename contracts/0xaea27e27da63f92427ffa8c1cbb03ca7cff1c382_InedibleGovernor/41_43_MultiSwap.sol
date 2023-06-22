// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

import "../interfaces/IUniswapV2Pair.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "hardhat/console.sol";

contract MultiSwap {
    IUniswapV2Pair public pool;

    constructor(address _pool) {
        pool = IUniswapV2Pair(_pool);
    }

    function swapNTimes(
        uint times,
        uint[] memory expectedAmounts,
        uint amount,
        address _tokenIn
    ) public {
        require(
            times == expectedAmounts.length,
            "times != expectedAmounts.length"
        );

        for (uint i = 0; i < times; i++) {
            IERC20(_tokenIn).transfer(address(pool), amount);
            pool.swap(expectedAmounts[0], 0, msg.sender, "");
        }
    }
}