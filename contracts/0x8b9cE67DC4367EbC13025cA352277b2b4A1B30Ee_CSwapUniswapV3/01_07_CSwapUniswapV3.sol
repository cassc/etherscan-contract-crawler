// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

import "ICSwapUniswapV3.sol";
import "ISwapRouter.sol";
import "CSwapBase.sol";

contract CSwapUniswapV3 is CSwapBase, ICSwapUniswapV3 {
    function _getContractName() internal pure override returns (string memory) {
        return "CSwapUniswapV3";
    }

    /** @notice Use this function to SELL a fixed amount of an asset.
        @dev This function sells an EXACT amount of `tokenIn` to receive `tokenOut`.
        If the price is worse than a threshold, the transaction will revert.
        @param amountIn The exact amount of `tokenIn` to sell.
        @param tokenIn The token to sell. Note: This must be an ERC20 token.
        @param tokenOut The token that the user wishes to receive. Note: This must be an ERC20 token.
        @param minAmountOut The minimum amount of `tokenOut` the user wishes to receive.
        @param params Additional parameters to specify UniswapV3 specific parameters. See ICSwapUniswapV3.sol
     */
    function sell(
        uint256 amountIn,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        UniswapV3SwapParams calldata params
    ) external payable {
        address receiver = params.receiver == address(0) ? address(this) : params.receiver;

        uint256 balanceBefore = _preSwap(
            tokenIn,
            tokenOut,
            address(params.router),
            amountIn,
            receiver
        );

        //solhint-disable-next-line not-rely-on-time
        uint256 deadline = params.deadline == 0 ? block.timestamp + 1 : params.deadline;

        ISwapRouter(params.router).exactInput(
            ISwapRouter.ExactInputParams({
                path: params.path,
                recipient: receiver,
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut
            })
        );

        _postSwap(balanceBefore, tokenOut, minAmountOut, receiver);
    }

    /** @notice Use this function to perform BUY a fixed amount of an asset.
        @dev This function buys an EXACT amount of `tokenOut` by spending `tokenIn`.
        If the price is worse than a threshold, the transaction will revert.
        @param amountOut The exact amount of `tokenOut` to buy.
        @param tokenOut The token to buy. Note: This must be an ERC20 token.
        @param tokenIn The token that the user wishes to spend. Note: This must be an ERC20 token.
        @param maxAmountIn The maximum amount of `tokenIn` that the user wishes to spend.
        @param params Additional parameters to specify UniswapV3 specific parameters. See ICSwapUniswapV3.sol
     */
    function buy(
        uint256 amountOut,
        IERC20 tokenOut,
        IERC20 tokenIn,
        uint256 maxAmountIn,
        UniswapV3SwapParams calldata params
    ) external payable {
        address receiver = params.receiver == address(0) ? address(this) : params.receiver;

        uint256 balanceBefore = _preSwap(
            tokenIn,
            tokenOut,
            address(params.router),
            maxAmountIn,
            receiver
        );

        //solhint-disable-next-line not-rely-on-time
        uint256 deadline = params.deadline == 0 ? block.timestamp + 1 : params.deadline;

        ISwapRouter(params.router).exactOutput(
            ISwapRouter.ExactOutputParams({
                path: params.path,
                recipient: receiver,
                deadline: deadline,
                amountOut: amountOut,
                amountInMaximum: maxAmountIn
            })
        );

        _postSwap(balanceBefore, tokenOut, amountOut, receiver);
    }
}