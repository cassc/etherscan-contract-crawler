// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface INTokenUniswapV3 {
    /**
     * @notice Decreases liquidity for underlying Uniswap V3 NFT LP and validates
     * that the user respects liquidation checks.
     * @param user The user address decreasing liquidity for
     * @param tokenId The id of the erc721 token
     * @param liquidityDecrease The amount of liquidity to remove of LP
     * @param amount0Min The minimum amount to remove of token0
     * @param amount1Min The minimum amount to remove of token1
     * @param receiveEthAsWeth If convert weth to ETH
     */
    function decreaseUniswapV3Liquidity(
        address user,
        uint256 tokenId,
        uint128 liquidityDecrease,
        uint256 amount0Min,
        uint256 amount1Min,
        bool receiveEthAsWeth
    ) external;
}