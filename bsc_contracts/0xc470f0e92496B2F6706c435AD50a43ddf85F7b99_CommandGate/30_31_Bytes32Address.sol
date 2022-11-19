// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Bytes32Address {
    function fromFirst20Bytes(
        bytes32 bytesValue
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            addr := bytesValue
        }
    }

    function fillLast12Bytes(
        address addressValue
    ) internal pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            value := addressValue
        }
    }

    function fromFirst160Bits(
        uint256 uintValue
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            addr := uintValue
        }
    }

    function fillLast96Bits(
        address addressValue
    ) internal pure returns (uint256 value) {
        /// @solidity memory-safe-assembly
        assembly {
            value := addressValue
        }
    }

    function fromLast160Bits(
        uint256 uintValue
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            addr := shr(0x60, uintValue)
        }
    }

    function fillFirst96Bits(
        address addressValue
    ) internal pure returns (uint256 value) {
        /// @solidity memory-safe-assembly
        assembly {
            value := shl(0x60, addressValue)
        }
    }
}