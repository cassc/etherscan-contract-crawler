// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "ICSwapUniswapV2.sol";
import "IUniswapV2Router02.sol";
import "IWeth.sol";
import "CSwapBase.sol";

contract CSwapUniswapV2 is CSwapBase, ICSwapUniswapV2 {
    function _getContractName() internal pure override returns (string memory) {
        return "CSwapUniswapV2";
    }

    function _validateParams(
        IERC20 tokenIn,
        IERC20 tokenOut,
        UniswapV2SwapParams calldata params
    ) internal view returns (UniswapV2SwapParams memory) {
        require(params.path[0] == address(tokenIn), "CSwapUniswapV2: invalid path in");
        require(
            params.path[params.path.length - 1] == address(tokenOut),
            "CSwapUniswapV2: invalid path out"
        );
        address receiver = params.receiver == address(0) ? address(this) : params.receiver;
        //solhint-disable-next-line not-rely-on-time
        uint256 deadline = params.deadline == 0 ? block.timestamp + 1 : params.deadline;
        return
            UniswapV2SwapParams({
                router: params.router,
                path: params.path,
                receiver: receiver,
                deadline: deadline
            });
    }

    /** @notice Use this function to SELL a fixed amount of an asset.
        @dev This function sells an EXACT amount of `tokenIn` to receive `tokenOut`.
        If the price is worse than a threshold, the transaction will revert.
        @param amountIn The exact amount of `tokenIn` to sell.
        @param tokenIn The token to sell. Note: This must be an ERC20 token.
        @param tokenOut The token that the user wishes to receive. Note: This must be an ERC20 token.
        @param minAmountOut The minimum amount of `tokenOut` the user wishes to receive.
        @param params Additional parameters to specify UniswapV2 specific parameters. See ICSwapUniswapV2.sol
     */
    function sell(
        uint256 amountIn,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        UniswapV2SwapParams calldata params
    ) external payable {
        UniswapV2SwapParams memory validatedParams = _validateParams(tokenIn, tokenOut, params);
        uint256 balanceBefore = _preSwap(
            tokenIn,
            tokenOut,
            validatedParams.router,
            amountIn,
            validatedParams.receiver
        );
        IUniswapV2Router02(validatedParams.router).swapExactTokensForTokens(
            amountIn,
            minAmountOut,
            validatedParams.path,
            validatedParams.receiver,
            validatedParams.deadline
        );
        _postSwap(balanceBefore, tokenOut, minAmountOut, validatedParams.receiver);
    }

    /** @notice Use this function to perform BUY a fixed amount of an asset.
        @dev This function buys an EXACT amount of `tokenOut` by spending `tokenIn`.
        If the price is worse than a threshold, the transaction will revert.
        @param amountOut The exact amount of `tokenOut` to buy.
        @param tokenOut The token to buy. Note: This must be an ERC20 token.
        @param tokenIn The token that the user wishes to spend. Note: This must be an ERC20 token.
        @param maxAmountIn The maximum amount of `tokenIn` that the user wishes to spend.
        @param params Additional parameters to specify UniswapV2 specific parameters. See ICSwapUniswapV2.sol
     */
    function buy(
        uint256 amountOut,
        IERC20 tokenOut,
        IERC20 tokenIn,
        uint256 maxAmountIn,
        UniswapV2SwapParams calldata params
    ) external payable {
        UniswapV2SwapParams memory validatedParams = _validateParams(tokenIn, tokenOut, params);
        uint256 balanceBefore = _preSwap(
            tokenIn,
            tokenOut,
            validatedParams.router,
            maxAmountIn,
            validatedParams.receiver
        );
        IUniswapV2Router02(validatedParams.router).swapTokensForExactTokens(
            amountOut,
            maxAmountIn,
            validatedParams.path,
            validatedParams.receiver,
            validatedParams.deadline
        );
        _postSwap(balanceBefore, tokenOut, amountOut, validatedParams.receiver);
    }
}