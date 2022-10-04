// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICostManagerFactoryHelper {
    
    function canOverrideCostManager(address account, address instance) external view returns (bool);
}