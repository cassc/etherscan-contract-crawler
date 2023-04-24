/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDistributor {
    function shares(address account) external view returns (uint256,uint256,uint256);
    function shareholderClaims(address account) external view returns (uint256);
}

contract pinksaleTokenDividendTracker {
    constructor() {}

    function getShared(address distributor,address account) external view returns (uint256,uint256,uint256) {
        return IDistributor(distributor).shares(account);
    }

    function getTotalClaimed(address distributor,address account) external view returns (uint256) {
        return IDistributor(distributor).shareholderClaims(account);
    }
}