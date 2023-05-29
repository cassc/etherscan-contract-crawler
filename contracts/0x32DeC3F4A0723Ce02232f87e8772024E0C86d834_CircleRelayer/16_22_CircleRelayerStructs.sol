// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

contract CircleRelayerStructs {
    struct TransferTokensWithRelay {
        uint8 payloadId; // == 1
        uint256 targetRelayerFee;
        uint256 toNativeTokenAmount;
        bytes32 targetRecipientWallet;
    }
}