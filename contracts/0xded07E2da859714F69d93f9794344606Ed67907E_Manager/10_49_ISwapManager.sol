// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./IManagerBase.sol";

interface ISwapManager is IManagerBase {
    function muffinSwapCallback(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        bytes calldata data
    ) external;

    /**
     * @notice                  Swap `amountIn` of one token for as much as possible of another token
     * @param tokenIn           Address of input token
     * @param tokenOut          Address of output token
     * @param tierChoices       Bitmap to select which tiers are allowed to swap (e.g. 0xFFFF to allow all possible tiers)
     * @param amountIn          Desired input amount
     * @param amountOutMinimum  Minimum output amount
     * @param recipient         Address of the recipient of the output token
     * @param fromAccount       True for using sender's internal account to pay
     * @param toAccount         True for storing output tokens in recipient's internal account
     * @param deadline          Transaction reverts if it's processed after deadline
     * @return amountOut        Output amount of the swap
     */
    function exactInSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient,
        bool fromAccount,
        bool toAccount,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    /**
     * @notice                  Swap `amountIn` of one token for as much as possible of another along the specified path
     * @param path              Multi-hop path
     * @param amountIn          Desired input amount
     * @param amountOutMinimum  Minimum output amount
     * @param recipient         Address of the recipient of the output token
     * @param fromAccount       True for using sender's internal account to pay
     * @param toAccount         True for storing output tokens in recipient's internal account
     * @param deadline          Transaction reverts if it's processed after deadline
     * @return amountOut        Output amount of the swap
     */
    function exactIn(
        bytes calldata path,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient,
        bool fromAccount,
        bool toAccount,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    /**
     * @notice                  Swap as little as possible of one token for `amountOut` of another token
     * @param tokenIn           Address of input token
     * @param tokenOut          Address of output token
     * @param tierChoices       Bitmap to select which tiers are allowed to swap (e.g. 0xFFFF to allow all possible tiers)
     * @param amountOut         Desired output amount
     * @param amountInMaximum   Maximum input amount to pay
     * @param recipient         Address of the recipient of the output token
     * @param fromAccount       True for using sender's internal account to pay
     * @param toAccount         True for storing output tokens in recipient's internal account
     * @param deadline          Transaction reverts if it's processed after deadline
     * @return amountIn         Input amount of the swap
     */
    function exactOutSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient,
        bool fromAccount,
        bool toAccount,
        uint256 deadline
    ) external payable returns (uint256 amountIn);

    /**
     * @notice                  Swap as little as possible of one token for `amountOut` of another along the specified path
     * @param path              Address of output token
     * @param amountOut         Desired output amount
     * @param amountInMaximum   Maximum input amount to pay
     * @param recipient         Address of the recipient of the output token
     * @param fromAccount       True for using sender's internal account to pay
     * @param toAccount         True for storing output tokens in recipient's internal account
     * @param deadline          Transaction reverts if it's processed after deadline
     * @return amountIn         Input amount of the swap
     */
    function exactOut(
        bytes calldata path,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient,
        bool fromAccount,
        bool toAccount,
        uint256 deadline
    ) external payable returns (uint256 amountIn);
}