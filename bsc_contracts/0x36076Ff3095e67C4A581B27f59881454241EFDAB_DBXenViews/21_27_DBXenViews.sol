// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DBXen.sol";
import "./DBXenERC20.sol";

/**
 * Helper contract used to optimize dbxen state queries made by clients.
 */
contract DBXenViews {

    /**
     * Main dbxen contract address to get the data from.
     */
    DBXen public dbxen;

    /**
     * Reward token address.
     */
    DBXenERC20 public dxn;

    /**
     * @param _dbXen DBXen.sol contract address
     */
    constructor(DBXen _dbXen) {
        dbxen = _dbXen;
    }

    /**
     * @return main dbxen contract native coin balance
     */
    function deb0xContractBalance() external view returns (uint256) {
        return address(dbxen).balance;
    }

    /**
     * @dev Withdrawable stake is the amount of dbxen reward tokens that are currently 
     * 'unlocked' and can be unstaked by a given account.
     * 
     * @param staker the address to query the withdrawable stake for
     * @return the amount in wei
     */
    function getAccWithdrawableStake(address staker)
        external
        view
        returns (uint256)
    {
        uint256 calculatedCycle = dbxen.getCurrentCycle();
        uint256 unlockedStake = 0;

        if (
            dbxen.accFirstStake(staker) != 0 &&
            calculatedCycle > dbxen.accFirstStake(staker)
        ) {
            unlockedStake += dbxen.accStakeCycle(
                staker,
                dbxen.accFirstStake(staker)
            );

            if (
                dbxen.accSecondStake(staker) != 0 &&
                calculatedCycle > dbxen.accSecondStake(staker)
            ) {
                unlockedStake += dbxen.accStakeCycle(
                    staker,
                    dbxen.accSecondStake(staker)
                );
            }
        }

        return dbxen.accWithdrawableStake(staker) + unlockedStake;
    }

    /**
     * @dev Unclaimed fees represent the native coin amount that has been allocated 
     * to a given account but was not claimed yet.
     * 
     * @param account the address to query the unclaimed fees for
     * @return the amount in wei
     */
    function getUnclaimedFees(address account) external view returns (uint256) {
        uint256 calculatedCycle = dbxen.getCurrentCycle();
        uint256 currentAccruedFees = dbxen.accAccruedFees(account);
        uint256 currentCycleFeesPerStakeSummed;
        uint256 previousStartedCycleTemp = dbxen.previousStartedCycle();
        uint256 lastStartedCycleTemp = dbxen.lastStartedCycle();

        if (calculatedCycle != dbxen.currentStartedCycle()) {
            previousStartedCycleTemp = lastStartedCycleTemp + 1;
            lastStartedCycleTemp = dbxen.currentStartedCycle();
        }

        if (
            calculatedCycle > lastStartedCycleTemp &&
            dbxen.cycleFeesPerStakeSummed(lastStartedCycleTemp + 1) == 0
        ) {
            uint256 feePerStake = 0;
            if(dbxen.summedCycleStakes(lastStartedCycleTemp) != 0){
                feePerStake = ((dbxen.cycleAccruedFees(
                lastStartedCycleTemp
            ) + dbxen.pendingFees()) * dbxen.SCALING_FACTOR()) /
                dbxen.summedCycleStakes(lastStartedCycleTemp);
            }

            currentCycleFeesPerStakeSummed =
                dbxen.cycleFeesPerStakeSummed(previousStartedCycleTemp) +
                feePerStake;
        } else {
            currentCycleFeesPerStakeSummed = dbxen.cycleFeesPerStakeSummed(
                dbxen.previousStartedCycle()
            );
        }

        uint256 currentRewards = getUnclaimedRewards(account);

        if (
            calculatedCycle > lastStartedCycleTemp &&
            dbxen.lastFeeUpdateCycle(account) != lastStartedCycleTemp + 1
        ) {
            currentAccruedFees +=
                (
                    (currentRewards *
                        (currentCycleFeesPerStakeSummed -
                            dbxen.cycleFeesPerStakeSummed(
                                dbxen.lastFeeUpdateCycle(account)
                            )))
                ) /
                dbxen.SCALING_FACTOR();
        }

        if (
            dbxen.accFirstStake(account) != 0 &&
            calculatedCycle > dbxen.accFirstStake(account) &&
            lastStartedCycleTemp + 1 > dbxen.accFirstStake(account)
        ) {
            currentAccruedFees +=
                (
                    (dbxen.accStakeCycle(account, dbxen.accFirstStake(account)) *
                        (currentCycleFeesPerStakeSummed - dbxen.cycleFeesPerStakeSummed(dbxen.accFirstStake(account)
                            )))
                ) /
                dbxen.SCALING_FACTOR();

            if (
                dbxen.accSecondStake(account) != 0 &&
                calculatedCycle > dbxen.accSecondStake(account) &&
                lastStartedCycleTemp + 1 > dbxen.accSecondStake(account)
            ) {
                currentAccruedFees +=
                    (
                        (dbxen.accStakeCycle(account, dbxen.accSecondStake(account)
                        ) *
                            (currentCycleFeesPerStakeSummed -
                                dbxen.cycleFeesPerStakeSummed(
                                    dbxen.accSecondStake(account)
                                )))
                    ) /
                    dbxen.SCALING_FACTOR();
            }
        }

        return currentAccruedFees;
    }

    /**
     * @return the reward token amount allocated for the current cycle
     */
    function calculateCycleReward() public view returns (uint256) {
        return (dbxen.lastCycleReward() * 10000) / 10020;
    }

    /**
     * @dev Unclaimed rewards represent the amount of dbxen reward tokens 
     * that were allocated but were not withdrawn by a given account.
     * 
     * @param account the address to query the unclaimed rewards for
     * @return the amount in wei
     */
    function getUnclaimedRewards(address account)
        public
        view
        returns (uint256)
    {
        uint256 currentRewards = dbxen.accRewards(account) -  dbxen.accWithdrawableStake(account);
        uint256 calculatedCycle = dbxen.getCurrentCycle();

       if (
            calculatedCycle > dbxen.lastActiveCycle(account) &&
            dbxen.accCycleBatchesBurned(account) != 0
        ) {
            uint256 lastCycleAccReward = (dbxen.accCycleBatchesBurned(account) *
                dbxen.rewardPerCycle(dbxen.lastActiveCycle(account))) /
                dbxen.cycleTotalBatchesBurned(dbxen.lastActiveCycle(account));

            currentRewards += lastCycleAccReward;
        }

        return currentRewards;
    }
}