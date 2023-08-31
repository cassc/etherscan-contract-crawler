// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

interface IMaliciousRegister{
    function isMaliciousAccount(address accountToCheck) external view returns (bool);

    function addMaliciousAccounts(address[] memory accountsToAdd) external returns (bool added);

    function removeMaliciousAccounts(address[] memory accountsToRemove) external returns (bool removed);
}