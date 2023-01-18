// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../libraries/Transfers.sol";
import "../libraries/Whitelist.sol";
import "../libraries/Errors.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/external/IHopBridge.sol";

contract HopAdapter is IAdapter {
    using Transfers for address;

    /// @notice ID of L1 chain (Ethereum)
    uint256 public constant L1_CHAIN_ID = 1;

    struct SendToL2Args {
        address bridge;
        uint256 chainId;
        address recipient;
        uint256 amountOutMin;
        uint256 deadline;
        address relayer;
        uint256 relayerFee;
    }

    struct SwapAndSendArgs {
        address bridge;
        uint256 chainId;
        address recipient;
        uint256 bonderFee;
        uint256 amountOutMin;
        uint256 deadline;
        uint256 destinationAmountOutMin;
        uint256 destinationDeadline;
    }

    /// @inheritdoc IAdapter
    function call(
        address tokenIn,
        uint256 amountIn,
        uint256,
        bytes memory args
    ) external payable override {
        /*
        Hop Bridge uses 2 interfaces for bridging depending on sneding being done from L1 or L2:
        1. If user sends funds from L1 (Ethereum Mainnet), he should use `sendToL2` function
        2. If users send funds from L2 (all other chains), he should use `swapAndSend` function
        */
        if (block.chainid == L1_CHAIN_ID) {
            // Decode bridge arguments
            SendToL2Args memory _args = abi.decode(args, (SendToL2Args));

            // Check that target is allowed
            require(
                Whitelist.isWhitelisted(_args.bridge),
                Errors.INVALID_TARGET
            );

            // Approve token
            tokenIn.approve(_args.bridge, amountIn);

            // Bridge
            uint256 _amountIn = (tokenIn == address(0)) ? amountIn : 0;
            IHopBridge(_args.bridge).sendToL2{value: _amountIn}(
                _args.chainId,
                _args.recipient,
                amountIn,
                _args.amountOutMin,
                _args.deadline,
                _args.relayer,
                _args.relayerFee
            );
        } else {
            // Decode bridge arguments
            SwapAndSendArgs memory _args = abi.decode(args, (SwapAndSendArgs));

            // Check that target is allowed
            require(
                Whitelist.isWhitelisted(_args.bridge),
                Errors.INVALID_TARGET
            );

            // Approve token
            tokenIn.approve(_args.bridge, amountIn);

            // Bridge
            uint256 _amountIn = (tokenIn == address(0)) ? amountIn : 0;
            IHopBridge(_args.bridge).swapAndSend{value: _amountIn}(
                _args.chainId,
                _args.recipient,
                amountIn,
                _args.bonderFee,
                _args.amountOutMin,
                _args.deadline,
                _args.destinationAmountOutMin,
                _args.destinationDeadline
            );
        }
    }
}