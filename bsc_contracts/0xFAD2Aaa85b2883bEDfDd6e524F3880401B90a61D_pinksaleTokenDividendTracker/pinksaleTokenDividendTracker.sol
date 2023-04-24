/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDistributor {
    function shareholderClaims(address account) external view returns (uint256);
}

contract pinksaleTokenDividendTracker {
    constructor() {}

    function getTotalClaimed(address distributor,address account) external view returns (uint256) {
        return IDistributor(distributor).shareholderClaims(account);
    }
}