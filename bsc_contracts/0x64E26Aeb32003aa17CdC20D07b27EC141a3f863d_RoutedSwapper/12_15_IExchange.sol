// SPDX-License-Identifier: MIT

pragma solidity <=0.8.9;

/**
 * @notice Exchange interface
 */
interface IExchange {
    /**
     * @notice Get *spot* quote
     * It will return the swap amount based on the current reserves of the given path (i.e. spot price)
     * @dev It shouldn't be used as oracle!!!
     */
    function getAmountsIn(uint256 _amountOut, bytes memory path_) external returns (uint256 _amountIn);

    /**
     * @notice Get *spot* quote
     * It will return the swap amount based on the current reserves of the given path (i.e. spot price)
     * @dev It shouldn't be used as oracle!!!
     */
    function getAmountsOut(uint256 amountIn_, bytes memory path_) external returns (uint256 _amountOut);

    /**
     * @notice Get *spot* quote
     * It will return the swap amount based on the current reserves of the best pair/path found (i.e. spot price)
     * @dev It shouldn't be used as oracle!!!
     */
    function getBestAmountIn(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) external returns (uint256 _amountIn, bytes memory _path);

    /**
     * @notice Get *spot* quote
     * It will return the swap amount based on the current reserves of the best pair/path found (i.e. spot price)
     * @dev It shouldn't be used as oracle!!!
     */
    function getBestAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut, bytes memory _path);

    /**
     * @notice Perform an exact input swap
     * @dev Should transfer `amountIn_` before performing swap
     */
    function swapExactInput(
        bytes calldata path_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address outReceiver_
    ) external returns (uint256 _amountOut);

    /**
     * @notice Perform an exact output swap
     * @dev Should transfer `amountInMax_` before performing swap
     * @dev Sends swap remains - if any - to the `inSender_`
     */
    function swapExactOutput(
        bytes calldata path_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address inSender_,
        address outRecipient_
    ) external returns (uint256 _amountIn);
}