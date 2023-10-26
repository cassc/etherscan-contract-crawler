//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "../libraries/QuestDataTypes.sol";

/** @title Interface fo Quest Board V2  */
/// @author Paladin
interface IQuestBoard {

    // Structs

    /** @notice Struct for a Period of a Quest */
    struct QuestPeriod {
        // Total reward amount that can be distributed for that period
        uint256 rewardAmountPerPeriod;
        // Min Amount of reward for each vote (for 1 veToken)
        uint256 minRewardPerVote;
        // Max Amount of reward for each vote (for 1 veToken)
        uint256 maxRewardPerVote;
        // Min Target Bias for the Gauge
        uint256 minObjectiveVotes;
        // Max Target Bias for the Gauge
        uint256 maxObjectiveVotes;
        // Amount of reward to distribute, at period closing
        uint256 rewardAmountDistributed;
        // Timestamp of the Period start
        uint48 periodStart;
        // Current state of the Period
        QuestDataTypes.PeriodState currentState;
    }

    /** @notice Struct holding the parameters of the Quest common for all periods */
    struct Quest {
        // Address of the Quest creator (caller of createQuest() method)
        address creator;
        // Address of the ERC20 used for rewards
        address rewardToken;
        // Address of the target Gauge
        address gauge;
        // Total number of periods for the Quest
        uint48 duration;
        // Timestamp where the 1st QuestPeriod starts
        uint48 periodStart;
        // Total amount of rewards paid for this Quest
        // If changes were made to the parameters of this Quest, this will account
        // any added reward amounts
        uint256 totalRewardAmount;
        // Quest Types
        QuestTypes types;
    }

    /** @notice Struct with all the Quest types */
    struct QuestTypes {
        QuestDataTypes.QuestVoteType voteType;
        QuestDataTypes.QuestRewardsType rewardsType;
        QuestDataTypes.QuestCloseType closeType;
    }

    /** @notice Struct for the local variables in _createQuest() method */
    struct CreateVars {
        address creator;
        uint256 rewardPerPeriod;
        uint256 minObjective;
        uint256 startPeriod;
        uint256 periodIterator;
        uint256 maxObjective;
    }

    /** @notice Struct for the local variables in extendQuest() method */
    struct ExtendVars {
        uint256 lastPeriod;
        address gauge;
        address rewardToken;
        uint256 rewardPerPeriod;
        uint256 periodIterator;
        uint256 minObjective;
        uint256 maxObjective;
        uint256 minRewardPerVote;
        uint256 maxRewardPerVote;
    }

    /** @notice Struct for the local variables in updateQuestParameters() methods */
    struct UpdateVars {
        uint256 remainingDuration;
        uint256 currentPeriod;
        uint256 newRewardPerPeriod;
        uint256 newMaxObjective;
        uint256 newMinObjective;
        uint256 periodIterator;
        uint256 lastPeriod;
        address creator;
    }

    // Events

    /** @notice Event emitted when the Board is Initialized */
    event Init(address distributor, address biasCalculator);

    /** @notice Event emitted when a new Quest is created */
    event NewQuest(
        uint256 indexed questID,
        address indexed creator,
        address indexed gauge,
        address rewardToken,
        uint48 duration,
        uint256 startPeriod
    );

    /** @notice Event emitted when the Quest duration is extended */
    event ExtendQuestDuration(uint256 indexed questID, uint256 addedDuration, uint256 addedRewardAmount);

    /** @notice Event emitted when a Quest parameters are updated */
    event UpdateQuestParameters(
        uint256 indexed questID,
        uint256 indexed updatePeriod,
        uint256 newMinRewardPerVote,
        uint256 newMaxRewardPerVote,
        uint256 addedPeriodRewardAmount
    );

    /** @notice Event emitted when Quest creator withdraw undistributed rewards */
    event WithdrawUnusedRewards(uint256 indexed questID, address recipient, uint256 amount);

    /** @notice Event emitted when a Period is Closed */
    event PeriodClosed(uint256 indexed questID, uint256 indexed period);
    /** @notice Event emitted when a Quest Period rools over the undistributed rewards */
    event RewardsRollover(uint256 indexed questID, uint256 newRewardPeriod, uint256 newMinRewardPerVote, uint256 newMaxRewardPerVote);

    /** @notice Event emitted when a Period Bias is fixed */
    event PeriodBiasFixed(uint256 indexed questID, uint256 indexed period, uint256 newBias);

    /** @notice Event emitted when a new reward token is whitelisted */
    event WhitelistToken(address indexed token, uint256 minRewardPerVote);
    /** @notice Event emitted when a reward token parameter is updated */
    event UpdateRewardToken(address indexed token, uint256 newMinRewardPerVote);
    /** @notice Event emitted when the contract is killed */
    event Killed(uint256 killTime);
    /** @notice Event emitted when the contract is unkilled */
    event Unkilled(uint256 unkillTime);
    /** @notice Event emitted when the Quest creator withdraw all unused funds (if the contract was killed) */
    event EmergencyWithdraw(uint256 indexed questID, address recipient, uint256 amount);

    /** @notice Event emitted when a new manager is approved */
    event ApprovedManager(address indexed manager);
    /** @notice Event emitted when a manager is removed */
    event RemovedManager(address indexed manager);
    /** @notice Event emitted when the Chest address is updated */
    event ChestUpdated(address oldChest, address newChest);
    /** @notice Event emitted when a custom fee ratio is set for a given address */
    event SetCustomFeeRatio(address indexed creator, uint256 customFeeRatio);
    /** @notice Event emitted when the Distributor address is updated */
    event DistributorUpdated(address oldDistributor, address newDistributor);
    /** @notice Event emitted when the fee ratio is updated */
    event PlatformFeeRatioUpdated(uint256 oldFeeRatio, uint256 newFeeRatio);
    /** @notice Event emitted when the minimum objective of votes is updated */
    event MinObjectiveUpdated(uint256 oldMinObjective, uint256 newMinObjective);
    
}