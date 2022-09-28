// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Temporary upgrade to help transfer balance from V1 to V2
interface IMigrator {
    function migrate(address payable toAddress) external;
}