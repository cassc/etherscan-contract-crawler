// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGeneralTaxDistributor {
    function distributeTax(address token) external returns (uint256);
    function distributeTaxAvoidOrigin(address token, address origin) external returns (uint256);
}