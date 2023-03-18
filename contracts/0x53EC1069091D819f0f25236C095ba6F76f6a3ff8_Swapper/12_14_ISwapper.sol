// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISwapper {
    enum SwapType {
        EXACT_INPUT,
        EXACT_OUTPUT
    }

    struct Call {
        address target;
        bytes data;
        uint256 value;
        bool isDelegateCall;
    }

    function getAmountInUsingOracle(address tokenIn_, address tokenOut_, uint256 amountOut_)
        external
        returns (uint256 _amountIn);

    function getAmountIn(address tokenIn_, address tokenOut_, uint256 amountOut_)
        external
        returns (uint256 _amountIn);

    function getAmountOutUsingOracle(address tokenIn_, address tokenOut_, uint256 amountIn_)
        external
        returns (uint256 _amountOut);

    function swapExactInput(address tokenIn_, address tokenOut_, uint256 amountIn_, uint256 amountOutMin_)
        external
        payable
        returns (uint256 _amountOut);

    function swapExactOutput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address receiver_
    ) external returns (uint256 _amountIn);
}