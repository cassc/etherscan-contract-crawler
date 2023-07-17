// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

interface IUniswapV2Router02 {
    /// @dev Adds liquidity to an ERC-20⇄ERC-20 pool.
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @dev Removes liquidity from an ERC-20⇄ERC-20 pool.
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @dev Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined
     *  by the path. The first element of path is the input token, the last is the output token, and any intermediate 
     *  elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function factory() external pure returns (address);
}