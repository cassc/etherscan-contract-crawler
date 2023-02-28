// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IInstallmentsCalc {
    // ================ View Functions ================

    function getFullInterestAmount(uint256 principal, uint256 interestRate) external returns (uint256);
}