// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import "../libraries/BytesLib.sol";

import "./TokenBridgeRelayerStructs.sol";

abstract contract TokenBridgeRelayerMessages is TokenBridgeRelayerStructs {
    using BytesLib for bytes;

    /**
     * @notice Encodes the TransferWithRelay struct into bytes.
     * @param transfer TransferWithRelay struct.
     * @return encoded TransferWithRelay struct encoded into bytes.
     */
    function encodeTransferWithRelay(
        TransferWithRelay memory transfer
    ) public pure returns (bytes memory encoded) {
       require(transfer.payloadId == 1, "invalid payloadId");
        encoded = abi.encodePacked(
            transfer.payloadId,
            transfer.targetRelayerFee,
            transfer.toNativeTokenAmount,
            transfer.targetRecipient
        );
    }

    /**
     * @notice Decodes an encoded `TransferWithRelay` struct.
     * @dev reverts if:
     * - the first byte (payloadId) does not equal 1
     * - the length of the payload has an unexpected length
     * @param encoded Encoded `TransferWithRelay` struct.
     * @return transfer `TransferTokenRelay` struct.
     */
    function decodeTransferWithRelay(
        bytes memory encoded
    ) public pure returns (TransferWithRelay memory transfer) {
        uint256 index = 0;

        // parse the payloadId
        transfer.payloadId = encoded.toUint8(index);
        index += 1;

        require(transfer.payloadId == 1, "invalid payloadId");

        // target relayer fee
        transfer.targetRelayerFee = encoded.toUint256(index);
        index += 32;

        // amount of tokens to convert to native assets
        transfer.toNativeTokenAmount = encoded.toUint256(index);
        index += 32;

        // recipient of the transfered tokens and native assets
        transfer.targetRecipient = encoded.toBytes32(index);
        index += 32;

        require(index == encoded.length, "invalid message length");
    }
}