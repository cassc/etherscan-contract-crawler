// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Util {
    function toStr(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory buffer = new bytes(len);
        while (_i != 0) {
            len -= 1;
            buffer[len] = bytes1(uint8(48 + uint256(_i % 10)));
            _i /= 10;
        }
        return string(buffer);
    }

    function toFloatStr(uint256 x) internal pure returns (string memory) {
        if (x >= 100) return "1";
        if (x <= 0) return "0";
        return string(abi.encodePacked(".", toStr(x)));
    }
}