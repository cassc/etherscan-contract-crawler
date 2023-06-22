// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IAddressProvider {
    // Get the address of the main registry contract.
    function get_registry() external view;
    function get_address(uint id) external view returns (address);
    // function get_id_info(uint id) external view returns (address, bool, uint, uint, string);

}