// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

abstract contract TokenBridgeRelayerStructs {
    struct TransferWithRelay {
        uint8 payloadId; // == 1
        uint256 targetRelayerFee;
        uint256 toNativeTokenAmount;
        bytes32 targetRecipient;
    }

    struct InternalTransferParams {
        address token;
        uint8 tokenDecimals;
        uint256 amount;
        uint256 toNativeTokenAmount;
        uint16 targetChain;
        bytes32 targetRecipient;
    }

    struct SwapRateUpdate {
        address token;
        uint256 value;
    }
}