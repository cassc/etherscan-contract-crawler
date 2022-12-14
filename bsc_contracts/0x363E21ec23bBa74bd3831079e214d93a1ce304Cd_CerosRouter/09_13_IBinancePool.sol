// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

interface IBinancePool {
    function stakeAndClaimCerts() external payable;

    function unstakeCertsFor(address recipient, uint256 shares) external;

    function getMinimumStake() external view returns (uint256);

    function getRelayerFee() external view returns (uint256);

    function pendingUnstakesOf(address claimer) external view returns (uint256);
}