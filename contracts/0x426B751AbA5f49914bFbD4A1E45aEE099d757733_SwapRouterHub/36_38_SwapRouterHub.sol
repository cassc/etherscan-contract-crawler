// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;
pragma abicoder v2;

import "./SwapRouter.sol";
import "./UniswapV3Router.sol";
import "./UniswapV2Router.sol";
import "./libraries/SwapPath.sol";
import "./libraries/Protocols.sol";
import "./interfaces/ISwapRouterHub.sol";
import "./CurveRouter.sol";
import "./AbstractSelfPermit2612.sol";

/// @title Gridex, Curve, UniswapV2 and UniswapV3 Swap Router
contract SwapRouterHub is
    SwapRouter,
    UniswapV3Router,
    UniswapV2Router,
    ISwapRouterHub,
    CurveRouter,
    AbstractSelfPermit2612
{
    using SwapPath for bytes;

    constructor(
        address _gridexGridFactory,
        address _uniswapV3PoolFactory,
        address _uniswapV2PoolFactory,
        address _weth9
    )
        AbstractPayments(_gridexGridFactory, _weth9)
        UniswapV3Router(_uniswapV3PoolFactory)
        UniswapV2Router(_uniswapV2PoolFactory)
    {}

    /// @inheritdoc ISwapRouterHub
    function exactMixedInput(
        ExactMixedInputParameters memory parameters
    ) public payable override checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        // msg.sender pays for the first hop
        address payer = _msgSender();
        uint256 i = 0;
        while (true) {
            bool hasMultipleGrids = parameters.path.hasMultipleGrids();
            if (parameters.path.getProtocol() == Protocols.GRIDEX) {
                parameters.amountIn = exactInputInternal(
                    parameters.amountIn,
                    hasMultipleGrids ? address(this) : parameters.recipient, // this contract keep the token of intermediate swaps within the path
                    0,
                    SwapCallbackData({
                        path: parameters.path.getFirstGrid(), // only the first grid in the path is necessary
                        payer: payer
                    })
                );
            } else if (parameters.path.getProtocol() == Protocols.UNISWAPV3) {
                parameters.amountIn = uniswapV3ExactInputInternal(
                    parameters.amountIn,
                    hasMultipleGrids ? address(this) : parameters.recipient, // this contract keep the token of intermediate swaps within the path
                    0,
                    UniswapV3SwapCallbackData({
                        path: parameters.path.getFirstGrid(), // only the first grid in the path is necessary
                        payer: payer
                    })
                );
            } else if (parameters.path.getProtocol() == Protocols.UNISWAPV2) {
                parameters.amountIn = uniswapV2ExactInputInternal(
                    parameters.amountIn,
                    parameters.path,
                    payer,
                    hasMultipleGrids ? address(this) : parameters.recipient
                );
            } else {
                if (i == 0) pay(parameters.path.getTokenA(), payer, address(this), parameters.amountIn);

                parameters.amountIn = curveExactInputInternal(
                    parameters.amountIn,
                    parameters.path,
                    parameters.path.getProtocol(),
                    hasMultipleGrids ? address(this) : parameters.recipient
                );
            }

            // decide whether to continue or terminate
            if (hasMultipleGrids) {
                unchecked {
                    i++;
                }
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
}