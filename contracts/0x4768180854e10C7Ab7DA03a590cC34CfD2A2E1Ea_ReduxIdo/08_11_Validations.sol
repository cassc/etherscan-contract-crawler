// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

library Validations {
    function revertOnZeroAddress(address _address) internal pure {
        require(address(0) != address(_address), "zero address not accepted!");
    }
}