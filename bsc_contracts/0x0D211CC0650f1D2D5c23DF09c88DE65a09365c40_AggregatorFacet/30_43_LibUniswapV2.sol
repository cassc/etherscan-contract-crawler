// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {IUniswapV2Router} from "../interfaces/uniswap-v2/IUniswapV2Router.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibRouter, Hop} from "./LibRouter.sol";

library LibUniswapV2 {
    using LibAsset for address;

    function swapUniswapV2(Hop memory h) internal {
        h.path[0].approve(h.addr, h.amountIn);
        IUniswapV2Router(h.addr).swapExactTokensForTokens(h.amountIn, 0, h.path, address(this), block.timestamp);
    }
}