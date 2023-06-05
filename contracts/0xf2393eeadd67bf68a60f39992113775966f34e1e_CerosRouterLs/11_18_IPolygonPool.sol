// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

interface IPolygonPool {
    function stakeAndClaimCerts(uint256 amount) external;

    function unstakeCertsFor(address recipient, uint256 shares, uint256 fee, uint256 useBeforeBlock, bytes memory signature) external payable;

    function getMinimumStake() external view returns (uint256);

    function getRelayerFee() external view returns (uint256);

    function pendingUnstakesOf(address claimer) external view returns (uint256);
}