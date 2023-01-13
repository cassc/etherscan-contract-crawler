// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISafeSwapTradeRouter {
    /// @notice Trade details
    struct Trade {
        uint256 amountIn;
        uint256 amountOut;
        address[] path;
        address payable to;
        uint256 deadline;
    }

    function getSwapFees(uint256 amountIn, address[] memory path) external view returns (uint256 _fees);  // Use this.
    function getSwapFee(uint256 amountIn, uint256 _amountOut, address tokenA, address tokenB) external view returns (uint256 _fee);

    function swapTokensForExactTokensWithFeeAmount(Trade calldata trade) external payable;
    function swapExactTokensForTokensWithFeeAmount(Trade calldata trade) external payable;
    function swapETHForExactTokensWithFeeAmount(Trade calldata trade, uint256 _feeAmount) external payable;
    function swapExactETHForTokensWithFeeAmount(Trade calldata trade, uint256 _feeAmount) external payable;
    function swapTokensForExactETHAndFeeAmount(Trade calldata trade) external payable;
    function swapExactTokensForETHAndFeeAmount(Trade calldata trade) external payable;

}