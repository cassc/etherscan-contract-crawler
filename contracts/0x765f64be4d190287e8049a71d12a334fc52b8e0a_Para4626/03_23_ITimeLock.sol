// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITimeLock {
    /**
     * @dev Function to claim assets from time-lock agreements
     * @param agreementIds Array of agreement IDs to be claimed
     */
    function claim(uint256[] calldata agreementIds) external;
}