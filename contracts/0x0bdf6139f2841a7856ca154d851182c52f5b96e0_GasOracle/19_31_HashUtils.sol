// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library HashUtils {
    function replaceChainBytes(
        bytes32 data,
        uint8 sourceChainId,
        uint8 destinationChainId
    ) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, data)
            mstore8(0x00, sourceChainId)
            mstore8(0x01, destinationChainId)
            result := mload(0x0)
        }
    }

    function hashWithSender(bytes32 message, bytes32 sender) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, message)
            mstore(0x20, sender)
            result := or(
                and(
                    message,
                    0xffff000000000000000000000000000000000000000000000000000000000000 // First 2 bytes
                ),
                and(
                    keccak256(0x00, 0x40),
                    0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff // Last 30 bytes
                )
            )
        }
    }

    function hashWithSenderAddress(bytes32 message, address sender) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, message)
            mstore(0x20, sender)
            result := or(
                and(
                    message,
                    0xffff000000000000000000000000000000000000000000000000000000000000 // First 2 bytes
                ),
                and(
                    keccak256(0x00, 0x40),
                    0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff // Last 30 bytes
                )
            )
        }
    }

    function hashed(bytes32 message) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, message)
            result := keccak256(0x00, 0x20)
        }
    }
}