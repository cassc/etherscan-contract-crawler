// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IRootButtonswapRouter} from "./IRootButtonswapRouter.sol";

interface IBasicButtonswapRouter is IRootButtonswapRouter {
    /**
     * @notice Adds liquidity to a pair, creating it if it doesn't exist yet, and transfers the liquidity tokens to the recipient.
     * @dev If the pair is empty, amountAMin and amountBMin are ignored.
     * If the pair is nonempty, it deposits as much of tokenA and tokenB as possible while maintaining 3 conditions:
     * 1. The ratio of tokenA to tokenB in the pair remains approximately the same
     * 2. The amount of tokenA in the pair is at least amountAMin but less than or equal to amountADesired
     * 3. The amount of tokenB in the pair is at least amountBMin but less than or equal to amountBDesired
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @param amountADesired The maximum amount of the first token to add to the pair.
     * @param amountBDesired The maximum amount of the second token to add to the pair.
     * @param amountAMin The minimum amount of the first token to add to the pair.
     * @param amountBMin The minimum amount of the second token to add to the pair.
     * @param movingAveragePrice0ThresholdBps The percentage threshold that movingAveragePrice0 can deviate from the current price.
     * @param to The address to send the liquidity tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountA The amount of tokenA actually added to the pair.
     * @return amountB The amount of tokenB actually added to the pair.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint16 movingAveragePrice0ThresholdBps,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /**
     * @notice Adds liquidity to a pair, opposite to the existing reservoir, and transfers the liquidity tokens to the recipient
     * @dev Since there at most one reservoir at a given time, some conditions are checked:
     * 1. If there is no reservoir, it rejects
     * 2. The token with the reservoir has its amountDesired parameter ignored
     * 3. The token with the reservoir has its amount deducted from the reservoir (checked against corresponding amountMin parameter)
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @param amountADesired The maximum amount of the first token to add to the pair.
     * @param amountBDesired The maximum amount of the second token to add to the pair.
     * @param amountAMin The minimum amount of the first token to add to the pair.
     * @param amountBMin The minimum amount of the second token to add to the pair.
     * @param to The address to send the liquidity tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountA The amount of tokenA actually added to the pair.
     * @return amountB The amount of tokenB actually added to the pair.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidityWithReservoir(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /**
     * @notice Removes liquidity from a pair, and transfers the tokens to the recipient.
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountAMin The minimum amount of the first token to withdraw from the pair.
     * @param amountBMin The minimum amount of the second token to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountA The amount of tokenA actually withdrawn from the pair.
     * @return amountB The amount of tokenB actually withdrawn from the pair.
     */
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
     * @notice Removes liquidity from the reservoir of a pair and transfers the tokens to the recipient.
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountAMin The minimum amount of the first token to withdraw from the pair.
     * @param amountBMin The minimum amount of the second token to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountA The amount of tokenA actually withdrawn from the pair.
     * @return amountB The amount of tokenB actually withdrawn from the pair.
     */
    function removeLiquidityFromReservoir(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice Similar to `removeLiquidity()` but utilizes the Permit signatures to reduce gas consumption.
     * Removes liquidity from a pair, and transfers the tokens to the recipient.
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountAMin The minimum amount of the first token to withdraw from the pair.
     * @param amountBMin The minimum amount of the second token to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @param approveMax Whether the signature is for the max uint256 or liquidity value
     * @param v Part of the signature
     * @param r Part of the signature
     * @param s Part of the signature
     * @return amountA The amount of tokenA actually withdrawn from the pair.
     * @return amountB The amount of tokenB actually withdrawn from the pair.
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice Given an ordered array of tokens, performs consecutive swaps from a specific amount of the first token to the last token in the array.
     * @param amountIn The amount of the first token to swap.
     * @param amountOutMin The minimum amount of the last token to receive from the swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Given an ordered array of tokens, performs consecutive swaps from the first token to a specific amount of the last token in the array.
     * @param amountOut The amount of the last token to receive from the swap.
     * @param amountInMax The maximum amount of the first token to swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}