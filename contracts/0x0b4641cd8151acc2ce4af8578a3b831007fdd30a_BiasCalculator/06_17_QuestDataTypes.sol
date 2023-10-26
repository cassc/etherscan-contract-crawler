//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

/** @title Data Types fo Quest Board V2  */
/// @author Paladin
library QuestDataTypes {

    // Enums

    /** @notice State of each Period for each Quest */
    enum PeriodState { ZERO, ACTIVE, CLOSED, DISTRIBUTED }
    // All Periods are ACTIVE at creation since the voters from past periods are also accounted for the future period

    /** @notice Types of Vote logic for Quests */
    enum QuestVoteType { NORMAL, BLACKLIST, WHITELIST }
    // NORMAL: basic vote logic
    // BLACKLIST: remove the blacklisted voters bias from the gauge biases
    // WHITELIST: only sum up the whitelisted voters biases

    /** @notice Types of Rewards logic for Quests */
    enum QuestRewardsType { FIXED, RANGE }
    // FIXED: reward per vote is fixed
    // RANGE: reward per vote is a range between min and max, based on the Quest completion between min objective and max objective

    /** @notice Types of logic for undistributed rewards when closing Quest periods */
    enum QuestCloseType { NORMAL, ROLLOVER, DISTRIBUTE }
    // NORMAL: undistributed rewards are available to be withdrawn by the creator
    // ROLLOVER: undistributed rewards are added to the next period, increasing the reward/vote parameter
    // DISTRIBUTE: undistributed rewards are sent to the gauge for direct distribution

}