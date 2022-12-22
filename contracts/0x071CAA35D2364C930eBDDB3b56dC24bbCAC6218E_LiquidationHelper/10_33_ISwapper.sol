// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9.0;

interface ISwapper {
    /// @dev swaps `_amountIn` of `_tokenIn` for `_tokenOut`. It might require approvals.
    /// @return amountOut amount of _tokenOut received
    function swapAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _priceProvider,
        address _siloAsset
    ) external returns (uint256 amountOut);

    /// @dev swaps `_tokenIn` for `_amountOut` of  `_tokenOut`. It might require approvals
    /// @return amountIn amount of _tokenIn spend
    function swapAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut,
        address _priceProvider,
        address _siloAsset
    ) external returns (uint256 amountIn);

    /// @return address that needs to have approval to spend tokens to execute a swap
    function spenderToApprove() external view returns (address);
}