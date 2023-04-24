// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// @notice Mocks just the address storage of RocketStorage
contract RocketStorageMock {
    mapping(bytes32 => address) addressStorage;

    function setAddress(bytes32 _key, address _value) external {
        addressStorage[_key] = _value;
    }

    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }
}