// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Gradient Protection (v0.1) helpers
 * @author cairoeth
 * @dev Contract which contains helper functions for main contract.
 **/
contract Helpers {
        /**
        * @dev Returns an address as a string memory
        * @param _address is address to transform
        **/
        function _toAsciiString(address _address) internal pure returns (string memory) {
            bytes memory s = new bytes(40);
            for (uint i = 0; i < 20; i++) {
                bytes1 b = bytes1(uint8(uint(uint160(_address)) / (2**(8*(19 - i)))));
                bytes1 hi = bytes1(uint8(b) / 16);
                bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
                s[2*i] = _char(hi);
                s[2*i+1] = _char(lo);            
            }
            return string(s);
        }

        /**
        * @dev Allows to manipulate bytes for toAsciiString function
        * @param b is a byte
        **/
        function _char(bytes1 b) internal pure returns (bytes1 c) {
            if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
            else return bytes1(uint8(b) + 0x57);
        }
}