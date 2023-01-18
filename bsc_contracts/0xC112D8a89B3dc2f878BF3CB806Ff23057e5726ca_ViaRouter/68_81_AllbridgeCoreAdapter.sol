// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../libraries/Whitelist.sol";
import "./AdapterBase.sol";
import "../interfaces/external/IAllbridgeCore.sol";

contract AllbridgeCoreAdapter is AdapterBase {
    struct AllbridgeCoreArgs {
        address approveTo;
        bytes32 recipient;
        uint8 destinationChainId;
        bytes32 receiveToken;
        uint256 nonce;
        uint8 messenger;
    }

    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) AdapterBase(target_) {}

    /// @inheritdoc AdapterBase
    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 extraNativeValue,
        bytes memory args
    ) external payable override {
        // Decode args to receive variables
        AllbridgeCoreArgs memory allbridgeArgs = abi.decode(
            args,
            (AllbridgeCoreArgs)
        );

        // Check that approve target is allowed
        require(
            Whitelist.isWhitelisted(allbridgeArgs.approveTo),
            Errors.INVALID_TARGET
        );

        // Approve token
        Transfers.approve(tokenIn, allbridgeArgs.approveTo, amountIn);

        // Send bridge transaction
        uint256 value = (tokenIn == address(0))
            ? amountIn + extraNativeValue
            : extraNativeValue;
        IAllbridgeCore(target).swapAndBridge{value: value}(
            bytes32(uint256(uint160(tokenIn))),
            amountIn,
            allbridgeArgs.recipient,
            allbridgeArgs.destinationChainId,
            allbridgeArgs.receiveToken,
            allbridgeArgs.nonce,
            allbridgeArgs.messenger
        );
    }
}