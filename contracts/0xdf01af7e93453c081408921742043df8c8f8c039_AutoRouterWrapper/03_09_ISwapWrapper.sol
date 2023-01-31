//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;

error ETHAmountInMismatch();

/**
 * @notice ISwapWrapper is the interface that all swap wrappers should implement.
 * This will be used to support swap protocols like Uniswap V2 and V3, Sushiswap, 1inch, etc.
 */
interface ISwapWrapper {
    /// @notice Event emitted after a successful swap.
    event WrapperSwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        address sender,
        address indexed recipient,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice Name of swap wrapper for UX readability.
    function name() external returns (string memory);

    /**
     * @notice Swap function. Generally we expect the implementer to call some exactAmountIn-like swap method, and so the documentation
     * is written with this in mind. However, the method signature is general enough to support exactAmountOut swaps as well.
     * @param _tokenIn Token to be swapped (or 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH).
     * @param _tokenOut Token to receive (or 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for ETH).
     * @param _recipient Receiver of `_tokenOut`.
     * @param _amount Amount of `_tokenIn` that should be swapped.
     * @param _data Additional data that the swap wrapper may require to execute the swap.
     * @return Amount of _tokenOut received.
     */
    function swap(address _tokenIn, address _tokenOut, address _recipient, uint256 _amount, bytes calldata _data)
        external
        payable
        returns (uint256);
}