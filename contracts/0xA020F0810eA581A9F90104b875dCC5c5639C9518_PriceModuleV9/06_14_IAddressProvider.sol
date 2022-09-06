// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAddressProvider {
    function get_registry() external view returns (address);
    function get_address(uint256) external view returns (address);
}