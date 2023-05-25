// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPOrchestratorInterfaceV2 {
    function prevClaimed(uint256) external returns (bool);

    function totalClaimed(uint256) external view returns (uint256);

    function bullLastClaim(uint256) external view returns (uint256);

    function godsMintingDate(uint256) external view returns (uint256);
}