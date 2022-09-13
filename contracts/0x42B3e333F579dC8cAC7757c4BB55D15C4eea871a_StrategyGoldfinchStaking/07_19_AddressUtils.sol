// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library AddressUtils {

    function validateOne(address _address) internal pure {
        require(_address != address(0), 'Empty address');
    }

    function validateOneAndReturn(address _address) internal pure returns (address) {
        validateOne(_address);
        return _address;
    }

    function validateMany(address[] memory _addresses) internal pure {
        for (uint256 index = 0; index < _addresses.length; index++) {
            validateOne(_addresses[index]);
        }
    }

    function validateManyAndReturn(address[] memory _addresses) internal pure returns (address[] memory) {
        validateMany(_addresses);
        return _addresses;
    }
}