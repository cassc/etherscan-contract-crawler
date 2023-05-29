// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/libraries/SafeCast.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/Path.sol";
import "@uniswap/v3-periphery/contracts/libraries/BytesLib.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
import "@uniswap/swap-router-contracts/contracts/base/PeripheryPaymentsWithFeeExtended.sol";
import "@uniswap/swap-router-contracts/contracts/base/OracleSlippage.sol";
import "@uniswap/swap-router-contracts/contracts/libraries/Constants.sol";
import "./OneExFee.sol";

/// @title Uniswap V3 Swap Router
/// @notice Router for stateless execution of swaps against Uniswap V3
abstract contract V3SwapRouter1EX is
    IV3SwapRouter,
    PeripheryPaymentsWithFeeExtended,
    OracleSlippage,
    OneExFee
{
    using Path for bytes;
    using BytesLib for bytes;
    using SafeCast for uint256;

    /// @dev Used as the placeholder value for amountInCached, because the computed amount in for an exact output swap
    /// can never actually be this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return
            IUniswapV3Pool(
                PoolAddress.computeAddress(
                    factory,
                    PoolAddress.getPoolKey(tokenA, tokenB, fee)
                )
            );
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
        bytes previousPool;
    }

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();
        CallbackValidation.verifyCallback(factory, tokenIn, tokenOut, fee);

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));

        // Current pool fee amount
        uint256 oneExFee = oneExFeePercent != 0
            ? FullMath.mulDivRoundingUp(
                amountToPay,
                fee * oneExFeePercent,
                1e8 - fee * oneExFeePercent
            )
            : 0;

        if (isExactInput) {
            if (oneExFee > 0) pay(tokenIn, data.payer, oneExFeeCollector, oneExFee);
            pay(tokenIn, data.payer, msg.sender, amountToPay);
        } else {
            // Pay to previous pool
            if (data.previousPool.length > 0) {
                uint256 amountOut = amount0Delta < 0
                    ? uint256(-amount0Delta)
                    : uint256(-amount1Delta);
                uint24 feePreviousPool = data.previousPool.toUint24(20);

                uint256 oneExFeePreviousPool = oneExFeePercent != 0
                    ? FullMath.mulDivRoundingUp(
                        amountOut,
                        feePreviousPool * oneExFeePercent,
                        1e8
                    )
                    : 0;

                if (oneExFeePreviousPool > 0)
                    pay(
                        tokenIn,
                        address(this),
                        oneExFeeCollector,
                        oneExFeePreviousPool
                    );

                pay(
                    tokenIn,
                    address(this),
                    data.previousPool.toAddress(0),
                    amountOut - oneExFeePreviousPool
                );
            }

            // either initiate the next swap or pay
            if (data.path.hasMultiplePools()) {
                data.previousPool = abi.encodePacked(
                    getPool(
                        tokenIn < tokenOut ? tokenIn : tokenOut,
                        tokenIn < tokenOut ? tokenOut : tokenIn,
                        fee
                    ),
                    fee
                );

                data.path = data.path.skipToken();
                exactOutputInternal(amountToPay + oneExFee, address(this), 0, data);
            } else {
                if (oneExFee > 0)
                    pay(tokenOut, data.payer, oneExFeeCollector, oneExFee);

                amountInCached = amountToPay + oneExFee;
                // note that because exact output swaps are executed in reverse order, tokenOut is actually tokenIn
                pay(tokenOut, data.payer, msg.sender, amountToPay);
            }
        }
    }

    /// @dev Performs a single exact input swap
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountOut) {
        // find and replace recipient addresses
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        // Calculate and transfer 1EX fee
        uint256 oneExFee = oneExFeePercent != 0
            ? FullMath.mulDivRoundingUp(amountIn, fee * oneExFeePercent, 1e8)
            : 0;
        int256 amountInFeeLess = (amountIn - oneExFee).toInt256();

        (int256 amount0, int256 amount1) = getPool(tokenIn, tokenOut, fee).swap(
            recipient,
            zeroForOne,
            amountInFeeLess,
            sqrtPriceLimitX96 == 0
                ? (
                    zeroForOne
                        ? TickMath.MIN_SQRT_RATIO + 1
                        : TickMath.MAX_SQRT_RATIO - 1
                )
                : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    /// @inheritdoc IV3SwapRouter
    function exactInputSingle(ExactInputSingleParams memory params)
        external
        payable
        override
        returns (uint256 amountOut)
    {
        // use amountIn == Constants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (params.amountIn == Constants.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            params.amountIn = IERC20(params.tokenIn).balanceOf(address(this));
        }

        amountOut = exactInputInternal(
            params.amountIn,
            params.recipient,
            params.sqrtPriceLimitX96,
            SwapCallbackData({
                path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut),
                payer: hasAlreadyPaid ? address(this) : msg.sender,
                previousPool: abi.encodePacked()
            })
        );

        require(amountOut >= params.amountOutMinimum, "Too little received");
    }

    /// @inheritdoc IV3SwapRouter
    function exactInput(ExactInputParams memory params)
        external
        payable
        override
        returns (uint256 amountOut)
    {
        // use amountIn == Constants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (params.amountIn == Constants.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            (address tokenIn, , ) = params.path.decodeFirstPool();
            params.amountIn = IERC20(tokenIn).balanceOf(address(this));
        }

        address payer = hasAlreadyPaid ? address(this) : msg.sender;

        while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();

            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                0,
                SwapCallbackData({
                    path: params.path.getFirstPool(), // only the first pool in the path is necessary
                    payer: payer,
                    previousPool: abi.encodePacked()
                })
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this);
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        require(amountOut >= params.amountOutMinimum, "Too little received");
    }

    /// @dev Performs a single exact output swap
    // return value = amountIn returned by swap + 1ExFee, is omitted to decrease gas usage
    function exactOutputInternal(
        uint256 amountOut,
        address recipient,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private {
        // find and replace recipient addresses
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        (address tokenOut, address tokenIn, uint24 fee) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0Delta, int256 amount1Delta) = getPool(tokenIn, tokenOut, fee)
            .swap(
                recipient,
                zeroForOne,
                -amountOut.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (
                        zeroForOne
                            ? TickMath.MIN_SQRT_RATIO + 1
                            : TickMath.MAX_SQRT_RATIO - 1
                    )
                    : sqrtPriceLimitX96,
                abi.encode(data)
            );

        uint256 amountOutReceived;
        amountOutReceived = zeroForOne
            ? uint256(-amount1Delta)
            : uint256(-amount0Delta);
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == amountOut);
    }

    /// @inheritdoc IV3SwapRouter
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        override
        returns (uint256 amountIn)
    {
        // avoid an SLOAD by using the swap return data
        exactOutputInternal(
            params.amountOut,
            params.recipient,
            params.sqrtPriceLimitX96,
            SwapCallbackData({
                path: abi.encodePacked(params.tokenOut, params.fee, params.tokenIn),
                payer: msg.sender,
                previousPool: abi.encodePacked()
            })
        );

        amountIn = amountInCached;
        require(amountIn <= params.amountInMaximum, "Too much requested");
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }

    /// @inheritdoc IV3SwapRouter
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        override
        returns (uint256 amountIn)
    {
        exactOutputInternal(
            params.amountOut,
            params.recipient,
            0,
            SwapCallbackData({
                path: params.path,
                payer: msg.sender,
                previousPool: abi.encodePacked()
            })
        );

        amountIn = amountInCached;
        require(amountIn <= params.amountInMaximum, "Too much requested");
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }
}