// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@maverick/contracts/contracts/interfaces/IFactory.sol";
import "@maverick/contracts/contracts/interfaces/IPool.sol";
import "@maverick/contracts/contracts/interfaces/IPosition.sol";
import "@maverick/contracts/contracts/interfaces/ISwapCallback.sol";
import "./external/IWETH9.sol";

interface ISlimRouter is ISwapCallback {
    /// @return Returns the address of WETH9
    function WETH9() external view returns (IWETH9);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        IPool pool;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint256 sqrtPriceLimitD18;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of
    //another token
    /// @param params The parameters necessary for the swap, encoded as
    //`ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        IPool pool;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of
    //another token
    /// @param params The parameters necessary for the swap, encoded as
    //`ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(IERC20 token, uint256 amountMinimum, address recipient) external payable;
}