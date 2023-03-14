// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/vault/IVaultRestricted.sol";
import "./VaultIndexActions.sol";

/**
 * @notice Implementation of the {IVaultRestricted} interface.
 *
 * @dev
 * VaultRestricted extends VaultIndexActions and exposes functions restricted for Spool specific contracts.
 * 
 * Index functions are executed when state changes are performed, to synchronize to vault with central Spool contract
 * 
 * Functions:
 * - payFees, called by fast withdraw, when user decides to fast withdraw its shares
 * - reallocate, called by spool, sets new strategy allocation values and calculates what
 *   strategies to withdraw from and deposit to, to achieve the desired allocation
 */
abstract contract VaultRestricted is IVaultRestricted, VaultIndexActions {
    using Bitwise for uint256;

    // =========== FAST WITHDRAW FEES ============ //

    /**
     * @notice  Notifies fee handler of user realized profits to calculate and store the fee.
     * @dev
     * Called by fast withdraw contract.
     * Fee handler updates the fee storage slots and returns calculated fee value
     * Fast withdraw transfers the calculated fee to the fee handler after.
     *
     * Requirements:
     *
     * - Caller must be the fast withdraw contract
     *
     * @param profit Total profit made by the user
     * @return Fee amount calculated from the profit
     */
    function payFees(uint256 profit) external override onlyFastWithdraw returns (uint256) {
        return _payFees(profit);
    }

    /* ========== SPOOL REALLOCATE ========== */

    /**
     * @notice Update vault strategy proportions and reallocate funds according to the new proportions.
     *
     * @dev 
     * Requirements:
     * 
     * - the caller must be the Spool contract
     * - reallocation must not be in progress
     * - new vault proportions must add up to `FULL_PERCENT`
     *
     * @param vaultStrategies Vault strategy addresses
     * @param newVaultProportions New vault proportions
     * @param finishedIndex Completed global index
     * @param activeIndex current active global index, that we're setting reallocate for
     *
     * @return withdrawProportionsArray array of shares to be withdrawn from each vault strategy, and be later deposited back to other vault strategies
     * @return newDepositProportions proportions to be deposited to strategies from all withdrawn funds (written in a uint word, 14bits each) values add up to `FULL_PERCENT`
     *
     */
    function reallocate(
        address[] memory vaultStrategies,
        uint256 newVaultProportions,
        uint256 finishedIndex,
        uint24 activeIndex
    ) 
        external 
        override
        onlySpool
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        noReallocation
        returns(uint256[] memory withdrawProportionsArray, uint256 newDepositProportions)
    {
        (withdrawProportionsArray, newDepositProportions) = _adjustAllocation(vaultStrategies, newVaultProportions, finishedIndex);

        proportions = newVaultProportions;

        reallocationIndex = activeIndex;
        _updateInteractedIndex(activeIndex);
        emit Reallocate(reallocationIndex, newVaultProportions);
    }

    /**
     * @notice Set new vault strategy allocation and calculate how the funds should be spread
     * 
     * @dev
     * Requirements:
     *
     * - new proportions must add up to 100% (`FULL_PERCENT`)
     * - vault must withdraw from at least one strategy
     * - vault must deposit to at least one strategy
     * - vault total underlying must be more than zero
     *
     * @param vaultStrategies Vault strategy addresses
     * @param newVaultProportions New vault proportions
     * @param finishedIndex Completed global index
     *
     * @return withdrawProportionsArray array of shares to be withdrawn from each vault strategy, and be later deposited back to other vault strategies
     * @return newDepositProportions proportions to be deposited to strategies from all withdrawn funds (written in a uint word, 14bits each) values add up to `FULL_PERCENT`
     */
    function _adjustAllocation(
        address[] memory vaultStrategies,
        uint256 newVaultProportions,
        uint256 finishedIndex
    )
        private returns(uint256[] memory, uint256)
    {
        uint256[] memory depositProportionsArray = new uint256[](vaultStrategies.length);
        uint256[] memory withdrawProportionsArray = new uint256[](vaultStrategies.length);

        (uint256[] memory stratUnderlyings, uint256 vaultTotalUnderlying) = _getStratsAndVaultUnderlying(vaultStrategies, finishedIndex);

        require(vaultTotalUnderlying > 0, "NUL");

        uint256 totalProportion;
        uint256 totalDepositProportion;
        uint256 lastDepositIndex;

        {
            // flags to check if reallocation will withdraw and reposit
            bool didWithdraw = false;
            bool willDeposit = false;
            for (uint256 i; i < vaultStrategies.length; i++) {
                uint256 newStratProportion = Bitwise.get14BitUintByIndex(newVaultProportions, i);
                totalProportion += newStratProportion;

                uint256 stratProportion;
                if (stratUnderlyings[i] > 0) {
                    stratProportion = (stratUnderlyings[i] * FULL_PERCENT) / vaultTotalUnderlying;
                }

                // if current proportion is more than new - withdraw
                if (stratProportion > newStratProportion) {
                    uint256 withdrawalProportion = stratProportion - newStratProportion;
                    if (withdrawalProportion < 10) // NOTE: skip if diff is less than 0.1%
                        continue;

                    uint256 withdrawalShareProportion = (withdrawalProportion * ACCURACY) / stratProportion;
                    withdrawProportionsArray[i] = withdrawalShareProportion;

                    didWithdraw = true;
                } else if (stratProportion < newStratProportion) {
                    // if less - prepare for deposit
                    uint256 depositProportion = newStratProportion - stratProportion;
                    if (depositProportion < 10) // NOTE: skip if diff is less than 0.1%
                        continue;

                    depositProportionsArray[i] = depositProportion;
                    totalDepositProportion += depositProportion;
                    lastDepositIndex = i;

                    willDeposit = true;
                }
            }

            // check if sum of new propotions equals to full percent
            require(
                totalProportion == FULL_PERCENT,
                "BPP"
            );

            // Check if withdraw happened and if deposit will, otherwise revert
            require(didWithdraw && willDeposit, "NRD");
        }

        // normalize deposit proportions to FULL_PERCENT
        uint256 newDepositProportions;
        uint256 totalDepositProp;
        for (uint256 i; i <= lastDepositIndex; i++) {
            if (depositProportionsArray[i] > 0) {
                uint256 proportion = (depositProportionsArray[i] * FULL_PERCENT) / totalDepositProportion;

                newDepositProportions = newDepositProportions.set14BitUintByIndex(i, proportion);
                
                totalDepositProp += proportion;
            }
        }
        
        newDepositProportions = newDepositProportions.set14BitUintByIndex(lastDepositIndex, FULL_PERCENT - totalDepositProp);

        // store reallocation deposit proportions
        depositProportions = newDepositProportions;

        return (withdrawProportionsArray, newDepositProportions);
    }

    /**
     * @notice Get strategies and vault underlying
     * @param vaultStrategies Array of vault strategy addresses
     * @param index Get the underlying amounts at index
     */
    function _getStratsAndVaultUnderlying(address[] memory vaultStrategies, uint256 index)
        private
        view
        returns (uint256[] memory, uint256)
    {
        uint256[] memory stratUnderlyings = new uint256[](vaultStrategies.length);

        uint256 vaultTotalUnderlying;
        for (uint256 i; i < vaultStrategies.length; i++) {
            uint256 stratUnderlying = spool.getVaultTotalUnderlyingAtIndex(vaultStrategies[i], index);

            stratUnderlyings[i] = stratUnderlying;
            vaultTotalUnderlying += stratUnderlying;
        }

        return (stratUnderlyings, vaultTotalUnderlying);
    }
}