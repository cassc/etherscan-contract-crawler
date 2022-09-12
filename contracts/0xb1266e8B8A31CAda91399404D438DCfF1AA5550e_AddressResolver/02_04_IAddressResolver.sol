// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressResolver {
    function getAddress(string calldata name) external view returns (address);
}