// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import "../libraries/BytesLib.sol";

import "./CircleRelayerStructs.sol";

contract CircleRelayerMessages is CircleRelayerStructs {
    using BytesLib for bytes;

    /**
     * @notice Serializes the `TransferTokensWithRelay` struct
     * @param transfer `TransferTokensWithRelay` struct
     * @return encoded Serialized `TransferTokensWithRelay` struct
     */
    function encodeTransferTokensWithRelay(
        TransferTokensWithRelay memory transfer
    ) public pure returns (bytes memory encoded) {
        require(transfer.payloadId == 1, "invalid payloadId");
        encoded = abi.encodePacked(
            transfer.payloadId,
            transfer.targetRelayerFee,
            transfer.toNativeTokenAmount,
            transfer.targetRecipientWallet
        );
    }

    /**
     * @notice Decodes an encoded `TransferTokensWithRelay` struct
     * @dev reverts if:
     * - the first byte (payloadId) does not equal 1
     * - the length of the payload has an unexpected length
     * @param encoded Encoded `TransferTokensWithRelay` struct
     * @return transfer `TransferTokensWithRelay` struct
     */
    function decodeTransferTokensWithRelay(
        bytes memory encoded
    ) public pure returns (TransferTokensWithRelay memory transfer) {
        uint256 index = 0;

        // parse the payloadId
        transfer.payloadId = encoded.toUint8(index);
        index += 1;

        require(transfer.payloadId == 1, "CIRCLE_RELAYER: invalid message payloadId");

        // target relayer fee
        transfer.targetRelayerFee = encoded.toUint256(index);
        index += 32;

        // amount of tokens to convert to native assets
        transfer.toNativeTokenAmount = encoded.toUint256(index);
        index += 32;

        // recipient of the transfered tokens and native assets
        transfer.targetRecipientWallet = encoded.toBytes32(index);
        index += 32;

        require(index == encoded.length, "CIRCLE_RELAYER: invalid message length");
    }
}