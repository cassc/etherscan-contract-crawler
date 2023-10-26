// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenerationIncrease {
    /**
     * This function is called by the TimedPolicies to update this contract on a generation increase.
     * Its presence on a contract implies that the contract's identifier is in the notificationHashes
     * array on the TimedPolicies contract.
     */
    function notifyGenerationIncrease() external;
}