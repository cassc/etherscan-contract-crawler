// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../SwapTokenBase.sol";

contract SwapTokenETH is SwapTokenBase {
    constructor(uint256 _fee, address _addr) SwapTokenBase(_fee, _addr) {}

    function UNISWAP_V2_ROUTER() internal pure override returns (IUniswapV2Router02) {
        return IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function UNISWAP_FACTORY() internal pure override returns (IUniswapV2Factory) {
        return IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    }
}