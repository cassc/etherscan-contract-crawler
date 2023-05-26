// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library StringLib {
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bytesStr = new bytes(len);
        uint256 k = len;
        j = _i;
        while (j != 0) {
            bytesStr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        _uintAsString = string(bytesStr);
    }
}