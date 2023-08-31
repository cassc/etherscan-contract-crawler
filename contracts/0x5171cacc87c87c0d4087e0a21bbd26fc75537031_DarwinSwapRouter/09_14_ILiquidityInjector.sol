// SPDX-License-Identifier: BSL-1.1

import {IERC20} from "./IERC20.sol";

pragma solidity ^0.8.14;

interface ILiquidityInjector {
    event BuyBackAndPair(IERC20 tokenSold, IERC20 tokenBought, uint amountSold, uint amountBought);

    function initialize(address _pair, address token0, address token1) external;
    function buyBackAndPair(IERC20 _buyToken) external;
}