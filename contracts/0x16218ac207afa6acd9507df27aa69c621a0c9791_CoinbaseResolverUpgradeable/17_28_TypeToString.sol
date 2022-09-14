// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

library TypeToString {
    /**
     * @notice Creates a hex based encoded string representation of the specified bytes.
     * @param b The bytes to be encoded.
     * @return _string The encoded string.
     */
    function bytesToString(bytes memory b)
        internal
        pure
        returns (string memory)
    {
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(b.length << 1);

        uint8 b1;
        uint8 b2;
        for (uint256 i = 0; i < b.length; i++) {
            assembly {
                let lb := mload(add(add(b, 0x01), i))
                b1 := and(shr(4, lb), 0x0f)
                b2 := and(lb, 0x0f)
            }

            _string[i * 2] = HEX[b1];
            _string[i * 2 + 1] = HEX[b2];
        }
        return string(abi.encodePacked("0x", _string));
    }

    /**
     * @notice Creates a hex based encoded string representation of the specified bytes4 variable.
     * @param b4 The bytes4 to be encoded.
     * @return _string The encoded string.
     */
    function bytes4ToString(bytes4 b4) internal pure returns (string memory) {
        bytes memory b = new bytes(4);

        assembly {
            mstore(add(b, 32), b4)
        }

        return bytesToString(b);
    }

    /**
     * @notice Creates a hex based encoded string representation of the specified bytes32 variable.
     * @param b32 The bytes32 to be encoded.
     * @return _string The encoded string.
     */
    function bytes32ToString(bytes32 b32) internal pure returns (string memory) {
        bytes memory b = new bytes(32);

        assembly {
            mstore(add(b, 32), b32)
        }

        return bytesToString(b);
    }

    /**
     * @notice Creates a lowercase string representation of the address.
     * @param a The address to be encoded.
     * @return _string The encoded string.
     */
    function addressToString(address a) internal pure returns (string memory) {
        bytes memory b = new bytes(20);

        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }

        return bytesToString(b);
    }

    /**
     * @notice Creates a checksum compliant string representation of the address.
     * @param a The address to be encoded.
     * @return _string The encoded string.
     */
    function addressToCheckSumCompliantString(address a)
        internal
        pure
        returns (string memory)
    {
        string memory str = addressToString(a);

        bytes memory b = new bytes(20);
        uint256 len;
        assembly {
            len := mload(str)

            mstore(add(b, 32), mul(a, exp(256, 12)))
        }

        assert(len == 42);

        assembly {
            mstore(str, 0x28)
            mstore(add(str, 0x20), mload(add(str, 0x22)))
            mstore(add(str, 0x40), shl(16, mload(add(str, 0x40))))
        }

        bytes32 nibblets = keccak256(abi.encodePacked(str));

        bytes memory HEX_LOWER = "0123456789abcdef";
        bytes memory HEX_UPPER = "0123456789ABCDEF";

        bytes memory _string = new bytes(40);

        uint8 b1;
        uint8 b2;
        for (uint8 i = 0; i < 20; i++) {
            assembly {
                let lb := mload(add(add(b, 0x01), i))
                b1 := and(shr(4, lb), 0x0f)
                b2 := and(lb, 0x0f)
            }

            _string[i * 2] = uint8(nibblets[i] >> 4) > 7
                ? HEX_UPPER[b1]
                : HEX_LOWER[b1];
            _string[i * 2 + 1] = uint8(nibblets[i] & 0x0f) > 7
                ? HEX_UPPER[b2]
                : HEX_LOWER[b2];
        }

        return string(abi.encodePacked("0x", _string));
    }
}