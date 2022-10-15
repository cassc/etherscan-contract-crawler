//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Constant state used by the swap router
library Constants {
    address internal constant SUSHI_FACTORY =
        0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address internal constant SUSHI_ROUTER =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    address internal constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address internal constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address internal constant UNISWAP_V3_FACTORY =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address internal constant UNISWAP_V3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}