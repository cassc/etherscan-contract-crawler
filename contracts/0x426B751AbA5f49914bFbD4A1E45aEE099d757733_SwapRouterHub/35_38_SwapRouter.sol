// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@gridexprotocol/core/contracts/interfaces/IGrid.sol";
import "@gridexprotocol/core/contracts/interfaces/callback/IGridSwapCallback.sol";
import "@gridexprotocol/core/contracts/libraries/GridAddress.sol";
import "@gridexprotocol/core/contracts/libraries/CallbackValidator.sol";
import "@gridexprotocol/core/contracts/libraries/BoundaryMath.sol";
import "./interfaces/ISwapRouter.sol";
import "./libraries/SwapPath.sol";
import "./AbstractPayments.sol";
import "./Multicall.sol";

/// @title Gridex Swap Router
/// @notice A stateless execution router adapted for the gridex protocol
abstract contract SwapRouter is IGridSwapCallback, ISwapRouter, AbstractPayments, Multicall {
    using SwapPath for bytes;
    using SafeCast for uint256;

    /// @dev This constant is used as a placeholder value for amountInCached; as the computed amount (for
    /// an exact output swap), will never reach this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached;

    constructor() {
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @dev Returns the grid for the given token pair and resolution. The grid contract may or may not exist.
    function getGrid(address tokenA, address tokenB, int24 resolution) private view returns (IGrid) {
        return IGrid(GridAddress.computeAddress(gridFactory, GridAddress.gridKey(tokenA, tokenB, resolution)));
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    /// @inheritdoc IGridSwapCallback
    function gridexSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external override {
        // swaps which are entirely contained within zero liquidity regions are not supported
        // SR_IAD: invalid amount delta
        require(amount0Delta > 0 || amount1Delta > 0, "SR_IAD");
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut, int24 resolution) = data.path.decodeFirstGrid();
        CallbackValidator.validate(gridFactory, GridAddress.gridKey(tokenIn, tokenOut, resolution));

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) pay(tokenIn, data.payer, _msgSender(), amountToPay);
        else {
            // either initiate the next swap or pay
            if (data.path.hasMultipleGrids()) {
                data.path = data.path.skipToken();
                exactOutputInternal(amountToPay, _msgSender(), 0, data);
            } else {
                amountInCached = amountToPay;
                // swap in/out because the exact output swaps are reversed
                tokenIn = tokenOut;
                pay(tokenIn, data.payer, _msgSender(), amountToPay);
            }
        }
    }

    /// @dev Performs a single exact input swap
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 priceLimitX96,
        SwapCallbackData memory data
    ) internal returns (uint256 amountOut) {
        // allow swapping to the router address with address 0
        recipient = recipient == address(0) ? address(this) : recipient;

        (IGrid grid, bool zeroForOne) = _decodeGridForExactInput(data);

        (int256 amount0, int256 amount1) = grid.swap(
            recipient,
            zeroForOne,
            amountIn.toInt256(),
            priceLimitX96 == 0 ? (zeroForOne ? BoundaryMath.MIN_RATIO : BoundaryMath.MAX_RATIO) : priceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function _decodeGridForExactInput(SwapCallbackData memory data) private view returns (IGrid grid, bool zeroForOne) {
        (address tokenIn, address tokenOut, int24 resolution) = data.path.decodeFirstGrid();
        return (getGrid(tokenIn, tokenOut, resolution), tokenIn < tokenOut);
    }

    /// @inheritdoc ISwapRouter
    function exactInputSingle(
        ExactInputSingleParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        amountOut = exactInputInternal(
            parameters.amountIn,
            parameters.recipient,
            parameters.priceLimitX96,
            SwapCallbackData({
                path: abi.encodePacked(parameters.tokenIn, uint8(0), parameters.resolution, parameters.tokenOut),
                payer: _msgSender()
            })
        );
        // SR_TLR: too little received
        require(amountOut >= parameters.amountOutMinimum, "SR_TLR");
    }

    /// @inheritdoc ISwapRouter
    function exactInput(
        ExactInputParameters memory parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        // msg.sender pays for the first hop
        address payer = _msgSender();

        while (true) {
            bool hasMultipleGrids = parameters.path.hasMultipleGrids();

            // the output of the previous swap is used as the input of the subsequent swap.
            parameters.amountIn = exactInputInternal(
                parameters.amountIn,
                hasMultipleGrids ? address(this) : parameters.recipient, // this contract keep the token of intermediate swaps within the path
                0,
                SwapCallbackData({
                    path: parameters.path.getFirstGrid(), // only the first grid in the path is necessary
                    payer: payer
                })
            );

            // decide whether to continue or terminate
            if (hasMultipleGrids) {
                // at this point, the caller has paid
                payer = address(this);
                parameters.path = parameters.path.skipToken();
            } else {
                amountOut = parameters.amountIn;
                break;
            }
        }
        // SR_TLR: too little received
        require(amountOut >= parameters.amountOutMinimum, "SR_TLR");
    }

    /// @dev Performs a single exact output swap
    function exactOutputInternal(
        uint256 amountOut,
        address recipient,
        uint160 priceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountIn) {
        // allow swapping to the router address with address 0
        recipient = recipient == address(0) ? address(this) : recipient;

        (IGrid grid, bool zeroForOne) = _decodeGridForExactOutput(data);

        (int256 amount0Delta, int256 amount1Delta) = grid.swap(
            recipient,
            zeroForOne,
            -amountOut.toInt256(),
            priceLimitX96 == 0 ? (zeroForOne ? BoundaryMath.MIN_RATIO : BoundaryMath.MAX_RATIO) : priceLimitX96,
            abi.encode(data)
        );

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // technically, it is possible to not receive all of the output amount,
        // so if PriceLimit is not specified, this possibility needs to be eliminated immediately
        if (priceLimitX96 == 0) require(amountOutReceived == amountOut, "SR_IAOR"); // SR_IAOR: invalid amount out received
    }

    function _decodeGridForExactOutput(
        SwapCallbackData memory data
    ) private view returns (IGrid grid, bool zeroForOne) {
        (address tokenOut, address tokenIn, int24 resolution) = data.path.decodeFirstGrid();
        return (getGrid(tokenIn, tokenOut, resolution), tokenIn < tokenOut);
    }

    /// @inheritdoc ISwapRouter
    function exactOutputSingle(
        ExactOutputSingleParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountIn) {
        // avoid an SLOAD by using the swap return data
        amountIn = exactOutputInternal(
            parameters.amountOut,
            parameters.recipient,
            parameters.priceLimitX96,
            SwapCallbackData({
                path: abi.encodePacked(parameters.tokenOut, uint8(0), parameters.resolution, parameters.tokenIn),
                payer: _msgSender()
            })
        );

        // SR_TMR: too much requested
        require(amountIn <= parameters.amountInMaximum, "SR_TMR");
        // must be reset, despite remaining unused in the single hop case
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @inheritdoc ISwapRouter
    function exactOutput(
        ExactOutputParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountIn) {
        // the payer is fixed as _msgSender() here, this is a non-issue as they only pay for the “final” exactOutput
        // swap, which happens first, swaps that follow are paid within nested callbacks
        exactOutputInternal(
            parameters.amountOut,
            parameters.recipient,
            0,
            SwapCallbackData({path: parameters.path, payer: _msgSender()})
        );

        amountIn = amountInCached;
        // SR_TMR: too much requested
        require(amountIn <= parameters.amountInMaximum, "SR_TMR");
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }
}