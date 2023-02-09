// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/*
 * @title Solidity Bytes Address Utility
 *
 * @dev Extract addresses from a packed bytes string
 */
library BytesAddressLib {
    /**
     * @notice returns the last 20 bytes, cast as an address
     * @param _bytes the bytes string
     * @return address the last address in the bytes string
     */
    function parseLastAddress(bytes memory _bytes) internal pure returns (address) {
        require(_bytes.length >= 20, "invalid bytes length");
        return toAddress(_bytes, _bytes.length - 20);
    }

    /**
     * @notice returns the first 20 bytes, cast as an address
     * @param _bytes the bytes string
     * @return address the first address in the bytes string
     */
    function parseFirstAddress(bytes memory _bytes) internal pure returns (address) {
        require(_bytes.length >= 20, "invalid bytes length");
        return toAddress(_bytes, 0);
    }

    /**
     * @notice chunks bytes into an array of 20 byte addresses
     * @param _bytes the bytes string
     * @return addresses the array of addresses extracted from teh bytes string
     */
    function toAddressArray(bytes memory _bytes) internal pure returns (address[] memory addresses) {
        require(_bytes.length % 20 == 0, "invalid bytes length");
        uint256 addressCount = _bytes.length / 20;
        addresses = new address[](addressCount);
        for (uint i = 0; i < addressCount; ) {
            addresses[i] = toAddress(_bytes, i * 20);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice extract address from bytes string at index
     * @param _bytes the bytes string
     * @param _start index to start extracting the next 20 bytes
     * @return address the extracted address
     */
    function toAddress(bytes memory _bytes, uint256 _start) private pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;
        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }
        return tempAddress;
    }
}