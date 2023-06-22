// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


abstract contract ProtectionPlanFactoryStorage {
    mapping(address => address) public userProtectionPlan;
    mapping(address => mapping(uint256 => bool)) internal _nonces;
    address public protocolDirectoryAddr;
    address internal _signer;
}