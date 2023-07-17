// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

interface IUniswapV2Pair {
    /// @dev Returns the address of the pair token with the lower sort order.
    function token0() external pure returns (address);

    /// @dev Returns the address of the pair token with the higher sort order.
    function token1() external pure returns (address);

    /**
     * @dev Returns the reserves of token0 and token1 used to price trades and distribute liquidity. See Pricing.
     *  Also returns the block.timestamp (mod 2**32) of the last block during which an interaction occured for the pair.
     */
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}