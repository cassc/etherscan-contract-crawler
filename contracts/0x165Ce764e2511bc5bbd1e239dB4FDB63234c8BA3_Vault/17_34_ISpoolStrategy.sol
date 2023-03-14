// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolStrategy {
    /* ========== FUNCTIONS ========== */

    function getUnderlying(address strat) external returns (uint128);
    
    function getVaultTotalUnderlyingAtIndex(address strat, uint256 index) external view returns(uint128);

    function addStrategy(address strat) external;

    function disableStrategy(address strategy, bool skipDisable) external;

    function runDisableStrategy(address strategy) external;

    function emergencyWithdraw(
        address strat,
        address withdrawRecipient,
        uint256[] calldata data
    ) external;
}