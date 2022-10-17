// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPOrchestratorInterfaceV3 {
    function getClaimableMeth(uint256 tokenId, uint256 _type)
        external
        view
        returns (uint256);

    function getOldClaimableMeth(uint256 tokenId, bool isGod)
        external
        view
        returns (uint256);

    function breedings(uint256) external view returns (uint256);

    function claimedTeenMeth(uint256) external view returns (uint256);

    function claimedMeth(uint256) external view returns (uint256);

    function lastChestOpen(uint256) external view returns (uint256);

    function godBulls(uint256) external view returns (bool);

    function isResurrected(uint256) external view returns (bool);

    function prevClaimed(uint256) external view returns (bool);

    function availableForRefund(uint256) external view returns (bool);
}