// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IMStable {
    // Nexus
    function getModule(bytes32) external view returns (address);

    // Savings Manager
    function savingsContracts(address) external view returns (address);

    // Savings Contract
    function exchangeRate() external view returns (uint256);

    function creditBalances(address) external view returns (uint256);

    function depositSavings(uint256) external;

    function redeem(uint256) external returns (uint256);

    function depositInterest(uint256) external;
}