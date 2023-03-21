pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

// this contract is for testing beacon upgradeable.
// test will try to upgrade implementation to this address, and call isNewImplementation() function.
// if it returns true, then it means upgrade is success
contract MockImplementationUpgrade {
    function isNewImplementation() external view returns (bool) {
        return true;
    }
}