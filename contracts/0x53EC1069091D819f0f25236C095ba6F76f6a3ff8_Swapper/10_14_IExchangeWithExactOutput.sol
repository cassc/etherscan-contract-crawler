// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IExchangeWithExactOutput {
    function getAmountIn(uint256 amountOut_, bytes memory path_) external returns (uint256 _amountIn);

    /**
     * @notice Perform an exact output swap
     * @dev Should transfer `amountInMax_` before performing swap
     * @dev Sends swap remains - if any - to the `remainingReceiver_`
     */
    function swapExactOutput(
        bytes calldata path_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address remainingReceiver_,
        address outRecipient_
    ) external returns (uint256 _amountIn);
}