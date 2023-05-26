//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library BitOperator{
    string private constant ERROR_OVERFLOW = "position should overflow";
    function getBitValueUint8(uint256 value, uint256 pos) internal pure returns(uint8){
        if (pos > 248) revert(ERROR_OVERFLOW);
        return uint8(value >> pos);
    }

    function getBitValueBool(uint256 value, uint256 pos) internal pure returns(bool){
        if (pos > 255) revert(ERROR_OVERFLOW);
        return ((value >> pos) & 0x01 == 1);
    }

    function setBitValueUint8(uint256 value, uint256 pos, uint8 set) internal pure returns(uint256){
        if (pos > 248) revert(ERROR_OVERFLOW);
        return (value & ~(0xFF << pos)) | (uint256(set) << pos);
    }

    function setBitValueBool(uint256 value, uint256 pos, bool set) internal pure returns(uint256){
        if (pos > 255) revert(ERROR_OVERFLOW);
        return (value & ~(0x01 << pos)) | ((set ? uint256(1) : uint256(0)) << pos);
    }

}