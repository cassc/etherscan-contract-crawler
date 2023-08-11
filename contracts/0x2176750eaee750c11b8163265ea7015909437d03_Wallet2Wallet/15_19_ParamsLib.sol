// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

library ParamsLib {
    function toBytes32(address _self) internal pure returns(bytes32) {
        return bytes32(uint(_self));
    }

    function toAddress(bytes32 _self) internal pure returns(address payable) {
        return address(uint(_self));
    }
}