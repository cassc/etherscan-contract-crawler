// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Errors.sol";

library AddressCast {
    function toBytes32(bytes calldata _addressBytes) internal pure returns (bytes32 result) {
        require(_addressBytes.length <= 32, Errors.INVALID_SIZE);
        result = bytes32(_addressBytes);
        unchecked {
            uint offset = 32 - _addressBytes.length;
            result = result >> (offset * 8);
        }
    }

    function toBytes32(address _address) internal pure returns (bytes32 result) {
        result = bytes32(uint(uint160(_address)));
    }

    function toBytes(bytes32 _addressBytes32, uint _size) internal pure returns (bytes memory result) {
        require(_size > 0 && _size <= 32, Errors.INVALID_SIZE);
        result = new bytes(_size);
        unchecked {
            uint256 offset = 256 - _size * 8;
            assembly {
                mstore(add(result, 32), shl(offset, _addressBytes32))
            }
        }
    }

    function toAddress(bytes32 _addressBytes32) internal pure returns (address result) {
        result = address(uint160(uint(_addressBytes32)));
    }

    function toAddress(bytes calldata _addressBytes) internal pure returns (address result) {
        require(_addressBytes.length == 20, Errors.INVALID_SIZE);
        result = address(bytes20(_addressBytes));
    }
}