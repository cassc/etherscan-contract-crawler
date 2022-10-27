// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveRegistryProvider {
    function get_registry() external view returns (address);
}