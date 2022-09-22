// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}