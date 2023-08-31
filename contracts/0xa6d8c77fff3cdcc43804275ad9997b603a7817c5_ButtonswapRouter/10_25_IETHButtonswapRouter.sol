// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IBasicButtonswapRouter} from "./IBasicButtonswapRouter.sol";
import {IETHButtonswapRouterErrors} from "./IETHButtonswapRouterErrors.sol";

interface IETHButtonswapRouter is IBasicButtonswapRouter, IETHButtonswapRouterErrors {
    /**
     * @notice Returns the address of the WETH token
     * @return WETH The address of the WETH token
     */
    function WETH() external view returns (address WETH);

    /**
     * @notice Similar to `addLiquidity` but one of the tokens is ETH wrapped into WETH.
     * Adds liquidity to a pair, creating it if it doesn't exist yet, and transfers the liquidity tokens to the recipient.
     * @dev If the pair is empty, amountTokenMin and amountETHMin are ignored.
     * If the pair is nonempty, it deposits as much of token and WETH as possible while maintaining 3 conditions:
     * 1. The ratio of token to WETH in the pair remains approximately the same
     * 2. The amount of token in the pair is at least amountTokenMin but less than or equal to amountTokenDesired
     * 3. The amount of WETH in the pair is at least amountETHMin but less than or equal to ETH sent
     * @param token The address of the non-WETH token in the pair.
     * @param amountTokenDesired The maximum amount of the non-ETH token to add to the pair.
     * @param amountTokenMin The minimum amount of the non-ETH token to add to the pair.
     * @param amountETHMin The minimum amount of ETH/WETH to add to the pair.
     * @param movingAveragePrice0ThresholdBps The percentage threshold that movingAveragePrice0 can deviate from the current price.
     * @param to The address to send the liquidity tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountToken The amount of token actually added to the pair.
     * @return amountETH The amount of ETH/WETH actually added to the pair.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint16 movingAveragePrice0ThresholdBps,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    /**
     * @notice Similar to `addLiquidityWithReservoir` but one of the tokens is ETH wrapped into WETH.
     *     Adds liquidity to a pair, opposite to the existing reservoir, and transfers the liquidity tokens to the recipient
     * @dev Since there at most one reservoir at a given time, some conditions are checked:
     * 1. If there is no reservoir, it rejects
     * 2. If the non-WETH token has the reservoir, amountTokenDesired parameter ignored.
     * 3. The token/WETH with the reservoir has its amount deducted from the reservoir (checked against corresponding amountMin parameter)
     * @param token The address of the non-WETH token in the pair.
     * @param amountTokenDesired The maximum amount of the non-WETH token to add to the pair.
     * @param amountTokenMin The minimum amount of the non-WETH token to add to the pair.
     * @param amountETHMin The minimum amount of WETH to add to the pair.
     * @param to The address to send the liquidity tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountToken The amount of the non-ETH token actually added to the pair.
     * @return amountETH The amount of WETH actually added to the pair.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidityETHWithReservoir(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    /**
     * @notice Similar to `removeLiquidity()` but one of the tokens is ETH wrapped into WETH.
     * Removes liquidity from a pair, and transfers the tokens to the recipient.
     * @param token The address of the non-WETH token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountTokenMin The minimum amount of the non-WETH token to withdraw from the pair.
     * @param amountETHMin The minimum amount of ETH/WETH to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountToken The amount of the non-WETH token actually withdrawn from the pair.
     * @return amountETH The amount of ETH/WETH actually withdrawn from the pair.
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice Similar to `removeLiquidityFromReservoir()` but one of the tokens is ETH wrapped into WETH.
     * Removes liquidity from the reservoir of a pair and transfers the tokens to the recipient.
     * @param token The address of the non-WETH token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountTokenMin The minimum amount of the non-WETH token to withdraw from the pair.
     * @param amountETHMin The minimum amount of ETH/WETH to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountToken The amount of the non-WETH token actually withdrawn from the pair.
     * @return amountETH The amount of ETH/WETH actually withdrawn from the pair.
     */
    function removeLiquidityETHFromReservoir(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice Similar to `removeLiquidityWETH()` but utilizes the Permit signatures to reduce gas consumption.
     * Removes liquidity from a pair where one of the tokens is ETH wrapped into WETH, and transfers the tokens to the recipient.
     * @param token The address of the non-WETH token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountTokenMin The minimum amount of the non-WETH token to withdraw from the pair.
     * @param amountETHMin The minimum amount of ETH/WETH to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @param approveMax Whether the signature is for the max uint256 or liquidity value
     * @param v Part of the signature
     * @param r Part of the signature
     * @param s Part of the signature
     * @return amountToken The amount of the non-WETH token actually withdrawn from the pair.
     * @return amountETH The amount of ETH/WETH actually withdrawn from the pair.
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice Similar to `swapExactTokensForTokens()` the first token is ETH wrapped into WETH.
     * Given an ordered array of tokens, performs consecutive swaps from a specific amount of the first token to the last token in the array.
     * @param amountOutMin The minimum amount of the last token to receive from the swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    /**
     * @notice Similar to `swapTokensForExactTokens()` the last token is ETH wrapped into WETH.
     * Given an ordered array of tokens, performs consecutive swaps from the first token to a specific amount of the last token in the array.
     * @param amountOut The amount of ETH to receive from the swap.
     * @param amountInMax The maximum amount of the first token to swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Similar to `swapExactTokensForTokens()` but the last token is ETH wrapped into WETH.
     * Given an ordered array of tokens, performs consecutive swaps from a specific amount of the first token to the last token in the array.
     * @param amountIn The amount of the first token to swap.
     * @param amountOutMin The minimum amount of the last token to receive from the swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Similar to `swapTokensForExactTokens()` but the first token is ETH wrapped into WETH.
     * Given an ordered array of tokens, performs consecutive swaps from the first token to a specific amount of the last token in the array.
     * @param amountOut The amount of the last token to receive from the swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
}