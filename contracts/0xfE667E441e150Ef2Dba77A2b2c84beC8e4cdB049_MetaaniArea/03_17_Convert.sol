// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Convert{
    //
    function boolToString(bool _from) internal pure returns(string memory){
        return _from == true ? "true" : "false";
    }

    
    function bytes32ToHexString(bytes memory buffer) internal pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }

}