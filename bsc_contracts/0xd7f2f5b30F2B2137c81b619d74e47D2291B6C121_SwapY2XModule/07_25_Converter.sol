// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library Converter {

    function toUint128(uint256 a) internal pure returns (uint128 b){
        b = uint128(a);
        require(a == b, 'C128');
    }

}