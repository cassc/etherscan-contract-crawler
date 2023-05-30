// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./AbstractPayments.sol";
import "./interfaces/IUniswapV3Router.sol";
import "./interfaces/IUniswapV3PoolMinimum.sol";
import "./libraries/SwapPath.sol";
import "./libraries/UniswapV3PoolAddress.sol";
import "./libraries/UniswapV3CallbackValidator.sol";
import "./libraries/Ratio.sol";

/// @title Uniswap V3 Swap Router
/// @notice A stateless execution router adapted for the Uniswap V3 protocol
abstract contract UniswapV3Router is IUniswapV3Router, AbstractPayments {
    using SwapPath for bytes;
    using SafeCast for uint256;

    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    uint256 private amountInCached;

    address public immutable uniswapV3PoolFactory;

    constructor(address _uniswapV3PoolFactory) {
        uniswapV3PoolFactory = _uniswapV3PoolFactory;
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getUniswapV3Pool(address tokenA, address tokenB, int24 fee) private view returns (IUniswapV3PoolMinimum) {
        return
            IUniswapV3PoolMinimum(
                UniswapV3PoolAddress.computeAddress(
                    uniswapV3PoolFactory,
                    UniswapV3PoolAddress.poolKey(tokenA, tokenB, uint24(fee))
                )
            );
    }

    struct UniswapV3SwapCallbackData {
        bytes path;
        address payer;
    }

    /// @inheritdoc IUniswapV3Router
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external override {
        // swaps which are entirely contained within zero liquidity regions are not supported
        require(amount0Delta > 0 || amount1Delta > 0);
        UniswapV3SwapCallbackData memory data = abi.decode(_data, (UniswapV3SwapCallbackData));
        (address tokenIn, address tokenOut, int24 fee) = data.path.decodeFirstGrid();
        UniswapV3CallbackValidator.validate(uniswapV3PoolFactory, tokenIn, tokenOut, uint24(fee));

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));

        if (isExactInput) pay(tokenIn, data.payer, _msgSender(), amountToPay);
        else {
            // either initiate the next swap or pay
            if (data.path.hasMultipleGrids()) {
                data.path = data.path.skipToken();
                uniswapV3ExactOutputInternal(amountToPay, _msgSender(), 0, data);
            } else {
                amountInCached = amountToPay;
                // note that tokenOut is actually tokenIn because exactOutput swaps are executed in reverse order
                pay(tokenOut, data.payer, _msgSender(), amountToPay);
            }
        }
    }

    /// @dev Performs a single exact input swap
    function uniswapV3ExactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 sqrtPriceLimitX96,
        UniswapV3SwapCallbackData memory data
    ) internal returns (uint256 amountOut) {
        // allow swapping to the router address with address 0
        recipient = recipient == address(0) ? address(this) : recipient;

        (address tokenIn, address tokenOut, int24 fee) = data.path.decodeFirstGrid();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            recipient,
            zeroForOne,
            amountIn.toInt256(),
            sqrtPriceLimitX96 == 0
                ? (zeroForOne ? Ratio.MIN_SQRT_RATIO_PLUS_ONE : Ratio.MAX_SQRT_RATIO_MINUS_ONE)
                : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    /// @inheritdoc IUniswapV3Router
    function uniswapV3ExactInputSingle(
        UniswapV3ExactInputSingleParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        amountOut = uniswapV3ExactInputInternal(
            parameters.amountIn,
            parameters.recipient,
            parameters.sqrtPriceLimitX96,
            UniswapV3SwapCallbackData({
                path: abi.encodePacked(parameters.tokenIn, uint8(0), parameters.fee, parameters.tokenOut),
                payer: _msgSender()
            })
        );
        // UV3R_TLR: too little received
        require(amountOut >= parameters.amountOutMinimum, "UV3R_TLR");
    }

    /// @inheritdoc IUniswapV3Router
    function uniswapV3ExactInput(
        UniswapV3ExactInputParameters memory parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        // the first hop is paid for by msg.sender
        address payer = _msgSender();

        while (true) {
            bool hasMultipleGrids = parameters.path.hasMultipleGrids();

            // the output of the previous swap is used as the input of the subsequent swap
            parameters.amountIn = uniswapV3ExactInputInternal(
                parameters.amountIn,
                hasMultipleGrids ? address(this) : parameters.recipient, // this contract keep the token of intermediate swaps within the path
                0,
                UniswapV3SwapCallbackData({
                    path: parameters.path.getFirstGrid(), // only the first pool in the path is necessary
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
        // UV3R_TLR: too little received
        require(amountOut >= parameters.amountOutMinimum, "UV3R_TLR");
    }

    /// @dev Performs a single exact output swap
    function uniswapV3ExactOutputInternal(
        uint256 amountOut,
        address recipient,
        uint160 sqrtPriceLimitX96,
        UniswapV3SwapCallbackData memory data
    ) internal returns (uint256 amountIn) {
        // allow swapping to the router address with address 0
        recipient = recipient == address(0) ? address(this) : recipient;

        (address tokenOut, address tokenIn, int24 fee) = data.path.decodeFirstGrid();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0Delta, int256 amount1Delta) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            recipient,
            zeroForOne,
            -amountOut.toInt256(),
            sqrtPriceLimitX96 == 0
                ? (zeroForOne ? Ratio.MIN_SQRT_RATIO_PLUS_ONE : Ratio.MAX_SQRT_RATIO_MINUS_ONE)
                : sqrtPriceLimitX96,
            abi.encode(data)
        );

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // technically, it is possible to not receive all of the output amount,
        // so if PriceLimit is not specified, this possibility needs to be eliminated immediately
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == amountOut, "UV3R_IAOR"); // UV3R_IAOR: invalid amount out received
    }

    /// @inheritdoc IUniswapV3Router
    function uniswapV3ExactOutputSingle(
        UniswapV3ExactOutputSingleParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountIn) {
        // avoid an SLOAD by using the swap return data
        amountIn = uniswapV3ExactOutputInternal(
            parameters.amountOut,
            parameters.recipient,
            parameters.sqrtPriceLimitX96,
            UniswapV3SwapCallbackData({
                path: abi.encodePacked(parameters.tokenOut, uint8(0), parameters.fee, parameters.tokenIn),
                payer: _msgSender()
            })
        );

        // UV3R_TMR: too much requested
        require(amountIn <= parameters.amountInMaximum, "UV3R_TMR");
        // must be reset, despite remaining unused in the single hop case
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @inheritdoc IUniswapV3Router
    function uniswapV3ExactOutput(
        UniswapV3ExactOutputParameters calldata parameters
    ) external payable override checkDeadline(parameters.deadline) returns (uint256 amountIn) {
        uniswapV3ExactOutputInternal(
            parameters.amountOut,
            parameters.recipient,
            0,
            UniswapV3SwapCallbackData({path: parameters.path, payer: _msgSender()})
        );

        amountIn = amountInCached;
        // UV3R_TMR: too much requested
        require(amountIn <= parameters.amountInMaximum, "UV3R_TMR");
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }
}