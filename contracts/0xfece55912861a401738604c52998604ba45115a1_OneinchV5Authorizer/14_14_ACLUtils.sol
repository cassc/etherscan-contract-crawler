// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
address constant ZERO_ADDRESS = address(0);

function getWrappedTokenAddress() view returns (address tokenAddress) {
    uint256 chainId = block.chainid;
    // ETH: WETH
    if (chainId == 1) return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Optimism: WETH
    if (chainId == 10) return 0x4200000000000000000000000000000000000006;

    // BSC: WBNB
    if (chainId == 56) return 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    // Polygon: WMATIC
    if (chainId == 137) return 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    // Arbitrum: WETH
    if (chainId == 42161) return 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    // Avalanche: WAVAX
    if (chainId == 43114) return 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    revert("Unsupport chain");
}