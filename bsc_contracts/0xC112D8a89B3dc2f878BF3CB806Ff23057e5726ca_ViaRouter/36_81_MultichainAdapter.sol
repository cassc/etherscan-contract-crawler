// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../libraries/Transfers.sol";
import "../libraries/Whitelist.sol";
import "../libraries/Errors.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/external/IMultichain.sol";

contract MultichainAdapter is IAdapter {
    using Transfers for address;

    struct AnySwapOutArgs {
        address multichainRouter;
        address anyToken;
        address receiver;
        uint256 chainid;
    }

    /// @inheritdoc IAdapter
    function call(
        address tokenIn,
        uint256 amountIn,
        uint256,
        bytes memory args
    ) external payable override {
        AnySwapOutArgs memory swapArgs = abi.decode(args, (AnySwapOutArgs));

        // Check that target is allowed
        require(
            Whitelist.isWhitelisted(swapArgs.multichainRouter),
            Errors.INVALID_TARGET
        );

        // Call bridge
        if (tokenIn == address(0)) {
            IMultichain(swapArgs.multichainRouter).anySwapOutNative{
                value: amountIn
            }({
                token: swapArgs.anyToken,
                to: swapArgs.receiver,
                toChainID: swapArgs.chainid
            });
        } else {
            tokenIn.approve(swapArgs.multichainRouter, amountIn);
            IMultichain(swapArgs.multichainRouter).anySwapOutUnderlying({
                token: swapArgs.anyToken,
                to: swapArgs.receiver,
                amount: amountIn,
                toChainID: swapArgs.chainid
            });
        }
    }
}