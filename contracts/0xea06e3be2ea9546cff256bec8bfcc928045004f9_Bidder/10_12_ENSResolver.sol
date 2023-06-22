// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

/// Interface for an ENS resolver
interface ENSResolver {
    function setName(string memory) external returns (bytes32);
}