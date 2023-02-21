// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StringPacker {
    // takes a string of 31 or less characters and converts it to bytes32
    function pack(string memory unpacked)
        internal
        pure
        returns (bytes32 packed)
    {
        // do not use this function in a lossy way, it will not work
        // only strings with 31 or less characters are stored in memory packed with their length value
        require(bytes(unpacked).length < 32);
        // shift the memory pointer to pack the length of the string into the high byte
        // by assigning this to the return value, the type of bytes32 means that, when returning,
        // the pointer continues to read into the string data
        assembly {
            packed := mload(add(unpacked, 31))
        }
    }

    // takes a bytes32 packed in the format above and unpacks it into a string
    function unpack(bytes32 packed)
        internal
        pure
        returns (string memory unpacked)
    {
        // get the high byte which stores the length of the string when unpacked
        uint256 len = uint256(packed >> 248);
        // ensure that the length of the unpacked string doesn't read beyond the input value
        require(len < 32);
        // initialize the return value with the length
        unpacked = string(new bytes(len));
        // shift the pointer so that the length will be at the bottom of the word to match string encoding
        // then store the packed value
        assembly {
            // Potentially writes into unallocated memory as the length in the packed form will trail off the end
            // This is fine as there are no other relevant memory values to overwrite
            mstore(add(unpacked, 31), packed)
        }
    }
}