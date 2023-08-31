// SPDX-License-Identifier: GPL-3.0-or-later

// ISanctionsList.sol - Simplified interface for the SanctionsList contract

pragma solidity ^0.8.17;

interface ISanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}