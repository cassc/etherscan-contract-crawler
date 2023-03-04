// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router.sol";
import "../interfaces/ISupport.sol";

struct SwapParams {
    IUniswapV2Router02 router;
    bool tokenForETH;
    bool supportFee;
    bool inputExact;
    uint256 amountIn;
    uint256 amountOutMin;
    uint256 deadline;
    address[] path;
    address to;
}
struct DEXParams {
    IUniswapV2Router02 router;
    IFactory factory;
}

struct Response {
    uint256 maxAmt;
    uint8 router1;
    uint8 router2;
    uint8 router3;
    address pathAddr1;
    address pathAddr2;
}