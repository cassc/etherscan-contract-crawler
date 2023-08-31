// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./base/InstantSwap.sol";

contract InstantSwapEthereum is InstantSwap {
    constructor(uint256 _teamFee, address _teamWallet) InstantSwap(_teamFee, _teamWallet) {}

    function UNISWAP_V2_ROUTER() internal pure override returns (IUniswapV2Router02) {
        return IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function UNISWAP_FACTORY() internal pure override returns (IUniswapV2Factory) {
        return IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    }
}