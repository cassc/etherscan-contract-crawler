//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library SafeCast {
    uint internal constant MAX_UINT = uint(int(-1));
    function toInt(uint value) internal pure returns(int){
        require(value < MAX_UINT, "CONVERT_OVERFLOW");
        return int(value);
    }
}