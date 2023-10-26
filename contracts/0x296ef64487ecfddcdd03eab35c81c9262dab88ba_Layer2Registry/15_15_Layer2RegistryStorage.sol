// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title
/// @notice
contract Layer2RegistryStorage   {

    // check whether the address is layer2 contract or not
    mapping (address => bool) internal _layer2s;

    // array-like storages
    // NOTE: unregistered layer2s could exists in that array. so, should check by layer2s(address)
    uint256 internal _numLayer2s;
    mapping (uint256 => address) internal _layer2ByIndex;

}