// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../owner/Operator.sol";
import "../interfaces/IUniswapV2Router.sol";

contract HasRouter is Operator {
    IUniswapV2Router public ROUTER = IUniswapV2Router(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    
    function setRouter(address router) external onlyOperator {
        ROUTER = IUniswapV2Router(router);
    }
}