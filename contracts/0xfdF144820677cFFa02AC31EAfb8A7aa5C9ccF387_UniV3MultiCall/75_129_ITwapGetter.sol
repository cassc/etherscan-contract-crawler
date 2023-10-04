// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITwapGetter {
    /**
     * @dev returns the twap for the given uniswap v3 pool
     * @param inToken Address of the In Token
     * @param outToken Address of the Out Token
     * @param twapInterval Time interval for the twap
     * @param uniswapV3Pool Address of the Uniswap V3 Pool
     * @return twap The twap (in out token) for the given uniswap v3 pool
     */
    function getTwap(
        address inToken,
        address outToken,
        uint32 twapInterval,
        address uniswapV3Pool
    ) external view returns (uint256 twap);

    /**
     * @dev returns the sqrt twap for the given uniswap v3 pool
     * @param uniswapV3Pool Address of the Uniswap V3 Pool
     * @param twapInterval Time interval for the twap
     * @return sqrtTwapPriceX96 The sqrt twap for the given uniswap v3 pool
     */
    function getSqrtTwapX96(
        address uniswapV3Pool,
        uint32 twapInterval
    ) external view returns (uint160 sqrtTwapPriceX96);
}