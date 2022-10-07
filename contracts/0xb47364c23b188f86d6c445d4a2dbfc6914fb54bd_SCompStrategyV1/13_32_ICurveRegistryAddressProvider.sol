// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface ICurveRegistryAddressProvider {
    function get_address(uint256 id) external returns (address);
}