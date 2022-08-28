/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface ICurveAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256 _id) external view returns (address);
}