// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IBNBPool {
    function stakeAndClaimCerts() external payable;

    function unstakeCerts(uint256 shares) external;
}