// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IVaultRestricted {
    /* ========== FUNCTIONS ========== */
    
    function reallocate(
        address[] calldata vaultStrategies,
        uint256 newVaultProportions,
        uint256 finishedIndex,
        uint24 activeIndex
    ) external returns (uint256[] memory, uint256);

    function payFees(uint256 profit) external returns (uint256 feesPaid);

    /* ========== EVENTS ========== */

    event Reallocate(uint24 indexed index, uint256 newProportions);
}