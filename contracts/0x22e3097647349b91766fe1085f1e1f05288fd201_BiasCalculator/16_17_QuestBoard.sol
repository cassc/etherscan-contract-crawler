//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
 

//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./oz/interfaces/IERC20.sol";
import "./oz/libraries/SafeERC20.sol";
import "./oz/utils/ReentrancyGuard.sol";
import "./libraries/QuestDataTypes.sol";
import "./interfaces/IQuestBoard.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IGauge.sol";
import "./MultiMerkleDistributor.sol";
import "./modules/BiasCalculator.sol";
import "./utils/Owner.sol";
import "./libraries/Errors.sol";

/** @title Warden Quest Board V2  */
/// @author Paladin
/*
    V2 of Quest Board allowing to blacklist or whitelist veToken voters
    and chose between fixed or ranged rewards distribution
*/

contract QuestBoard is IQuestBoard, Owner, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Storage

    /** @notice Address of the Curve Gauge Controller */
    address public immutable GAUGE_CONTROLLER;

    /** @notice Seconds in a Week */
    uint256 private constant WEEK = 604800;
    /** @notice 1e18 scale */
    uint256 private constant UNIT = 1e18;
    /** @notice Max BPS value (100%) */
    uint256 private constant MAX_BPS = 10000;
    /** @notice Delay where contract can be unkilled */
    uint256 private constant KILL_DELAY = 2 * 604800; //2 weeks

    /** @notice ID for the next Quest to be created */
    uint256 public nextID;

    /** @notice List of Quest (indexed by ID) */
    // ID => Quest
    mapping(uint256 => Quest) public quests;
    /** @notice List of timestamp periods the Quest is active in */
    // QuestID => Periods (timestamps)
    mapping(uint256 => uint48[]) private questPeriods;
    /** @notice Mapping of all QuestPeriod struct for each period of each Quest */
    // QuestID => period => QuestPeriod
    mapping(uint256 => mapping(uint256 => QuestPeriod)) public periodsByQuest;
    /** @notice All the Quests present in this period */
    // period => array of Quest
    mapping(uint256 => uint256[]) private questsByPeriod;
    /** @notice All the Quests present in this period for each gauge */
    // gauge => period => array of Quest
    mapping(address => mapping(uint256 => uint256[])) private questsByGaugeByPeriod;
    /** @notice Mapping of Distributors used by each Quest to send rewards */
    // ID => Distributor
    mapping(uint256 => address) public questDistributors;
    /** @notice Amount not distributed, for Quest creators to redeem */
    mapping(uint256 => uint256) public questWithdrawableAmount;


    /** @notice Platform fees ratio (in BPS) */
    uint256 public platformFeeRatio = 400;
    /** @notice Mapping of specific fee ratio for some Quest creators */
    // Creator => specific fee
    mapping(address => uint256) public customPlatformFeeRatio;

    /** @notice Minimum Objective required */
    uint256 public objectiveMinimalThreshold;

    /** @notice Address of the Chest to receive platform fees */
    address public questChest;
    /** @notice Address of the reward Distributor contract */
    address public distributor;
    /** @notice Address of the Bias Calculator Module */
    address public biasCalculator;

    /** @notice Mapping of addresses allowed to call manager methods */
    mapping(address => bool) private approvedManagers;
    /** @notice Whitelisted tokens that can be used as reward tokens */
    mapping(address => bool) public whitelistedTokens;
    /** @notice Min rewardPerVote per token (to avoid spam creation of useless Quest) */
    mapping(address => uint256) public minRewardPerVotePerToken;

    /** @notice Boolean, true if the cotnract was killed, stopping main user functions */
    bool public isKilled;
    /** @notice Timestamp when the contract was killed */
    uint256 public killTs;

    

    // Modifiers

    /** @notice Check the caller is either the admin or an approved manager */
    modifier onlyAllowed(){
        if(!approvedManagers[msg.sender] && msg.sender != owner()) revert Errors.CallerNotAllowed();
        _;
    }

    /** @notice Check that contract was not killed */
    modifier isAlive(){
        if(isKilled) revert Errors.Killed();
        _;
    }

    /** @notice Check that contract was initialized */
    modifier isInitialized(){
        if(distributor == address(0)) revert Errors.NotInitialized();
        _;
    }


    // Constructor
    constructor(address _gaugeController, address _chest){
        if(
            _gaugeController == address(0)
            || _chest == address(0)
        ) revert Errors.AddressZero();

        GAUGE_CONTROLLER = _gaugeController;

        questChest = _chest;

        objectiveMinimalThreshold = 1000 * UNIT;
    }

   
    /**
    * @notice Initialize the contract
    * @param _distributor Address of the Distributor
    * @param _biasCalculator Address of the Bias Calculator
    */
    function init(address _distributor, address _biasCalculator) external onlyOwner {
        if(distributor != address(0)) revert Errors.AlreadyInitialized();
        if(_distributor == address(0) || _biasCalculator == address(0)) revert Errors.AddressZero();

        distributor = _distributor;
        biasCalculator= _biasCalculator;

        emit Init(_distributor, _biasCalculator);
    }


    // View Functions
   
    /**
    * @notice Returns the current Period for the contract
    * @dev Returns the current Period for the contract
    */
    function getCurrentPeriod() public view returns(uint256) {
        return (block.timestamp / WEEK) * WEEK;
    }
   
    /**
    * @notice Returns the list of all Quest IDs active on a given period
    * @dev Returns the list of all Quest IDs active on a given period
    * @param period Timestamp of the period
    * @return uint256[] : Quest IDs for the period
    */
    function getQuestIdsForPeriod(uint256 period) external view returns(uint256[] memory) {
        period = (period / WEEK) * WEEK;
        return questsByPeriod[period];
    }
   
    /**
    * @notice Returns the list of all Quest IDs active on a given period
    * @dev Returns the list of all Quest IDs active on a given period
    * @param period Timestamp of the period
    * @return uint256[] : Quest IDs for the period
    */
    function getQuestIdsForPeriodForGauge(address gauge, uint256 period) external view returns(uint256[] memory) {
        period = (period / WEEK) * WEEK;
        return questsByGaugeByPeriod[gauge][period];
    }
   
    /**
    * @notice Returns all periods for a Quest
    * @dev Returns all period timestamps for a Quest ID
    * @param questId ID of the Quest
    * @return uint256[] : List of period timestamps
    */
    function getAllPeriodsForQuestId(uint256 questId) external view returns(uint48[] memory) {
        return questPeriods[questId];
    }
   
    /**
    * @notice Returns all QuestPeriod of a given Quest
    * @dev Returns all QuestPeriod of a given Quest ID
    * @param questId ID of the Quest
    * @return QuestPeriod[] : list of QuestPeriods
    */
    function getAllQuestPeriodsForQuestId(uint256 questId) external view returns(QuestPeriod[] memory) {
        uint256 nbPeriods = questPeriods[questId].length;
        QuestPeriod[] memory periods = new QuestPeriod[](nbPeriods);
        for(uint256 i; i < nbPeriods;){
            periods[i] = periodsByQuest[questId][questPeriods[questId][i]];
            unchecked{ ++i; }
        }
        return periods;
    }
   
    /**
    * @notice Returns the number of periods to come for a given Quest
    * @dev Returns the number of periods to come for a given Quest
    * @param questID ID of the Quest
    * @return uint : remaining duration (non active periods)
    */
    function _getRemainingDuration(uint256 questID) internal view returns(uint256) {
        // Since we have the current period, the start period for the Quest, and each period is 1 WEEK
        // We can find the number of remaining periods in the Quest simply by dividing the remaining time between
        // currentPeriod and the last QuestPeriod start, plus 1 WEEK, by a WEEK.
        // If the current period is the last period of the Quest, we want to return 1
        if(questPeriods[questID].length == 0) revert Errors.EmptyQuest();
        uint256 lastPeriod = questPeriods[questID][questPeriods[questID].length - 1];
        uint256 currentPeriod = getCurrentPeriod();
        return lastPeriod < currentPeriod ? 0: ((lastPeriod - currentPeriod) + WEEK) / WEEK;
    }

    /**
    * @notice Returns the current reduced bias of a gauge for a given Quest
    * @dev Returns the current reduced bias of a gauge for a given Quest
    * @param questID ID of the Quest
    * @return uint256 : current reduced bias of the gauge
    */
    function getCurrentReducedBias(uint256 questID) external view returns(uint256) {
        return BiasCalculator(biasCalculator).getCurrentReducedBias(
            questID,
            quests[questID].gauge,
            quests[questID].types.voteType
        );
    }

    /**
    * @notice Returns the address of the Quest creator
    * @dev Returns the address of the Quest creator
    * @param questID ID of the Quest
    * @return address : creator of the Quest
    */
    function getQuestCreator(uint256 questID) external view returns(address){
        return quests[questID].creator;
    }


    // Functions

    /**
    * @notice Creates a fixed rewards Quest based on the given parameters
    * @dev Creates a Quest based on the given parameters & the given types with the Fixed Rewards type
    * @param gauge Address of the gauge
    * @param rewardToken Address of the reward token
    * @param startNextPeriod (bool) true to start the Quest the next period
    * @param duration Duration of the Quest (in weeks)
    * @param rewardPerVote Amount of reward/vote (in wei)
    * @param totalRewardAmount Total amount of rewards available for the full Quest duration
    * @param feeAmount Amount of fees paid at creation
    * @param voteType Vote type for the Quest
    * @param closeType Close type for the Quest
    * @param voterList List of voters for the Quest (to be used for Blacklist or Whitelist)
    * @return uint256 : ID of the newly created Quest
    */
    function createFixedQuest(
        address gauge,
        address rewardToken,
        bool startNextPeriod,
        uint48 duration,
        uint256 rewardPerVote,
        uint256 totalRewardAmount,
        uint256 feeAmount,
        QuestDataTypes.QuestVoteType voteType,
        QuestDataTypes.QuestCloseType closeType,
        address[] calldata voterList
    ) external nonReentrant isAlive isInitialized returns(uint256) {
        // Set the Quest Types for the new Quest
        QuestTypes memory types = QuestTypes({
            voteType: voteType,
            rewardsType: QuestDataTypes.QuestRewardsType.FIXED,
            closeType: closeType
        });

        return _createQuest(
            gauge,
            rewardToken,
            types,
            startNextPeriod,
            duration,
            rewardPerVote,
            rewardPerVote,
            totalRewardAmount,
            feeAmount,
            voterList
        );
    }

    /**
    * @notice Creates a ranged rewards Quest based on the given parameters
    * @dev Creates a Quest based on the given parameters & the given types with the Ranged Rewards type
    * @param gauge Address of the gauge
    * @param rewardToken Address of the reward token
    * @param startNextPeriod (bool) true to start the Quest the next period
    * @param duration Duration of the Quest (in weeks)
    * @param minRewardPerVote Minimum amount of reward/vote (in wei)
    * @param maxRewardPerVote Maximum amount of reward/vote (in wei)
    * @param totalRewardAmount Total amount of rewards available for the full Quest duration
    * @param feeAmount Amount of fees paid at creation
    * @param voteType Vote type for the Quest
    * @param closeType Close type for the Quest
    * @param voterList List of voters for the Quest (to be used for Blacklist or Whitelist)
    * @return uint256 : ID of the newly created Quest
    */
    function createRangedQuest(
        address gauge,
        address rewardToken,
        bool startNextPeriod,
        uint48 duration,
        uint256 minRewardPerVote,
        uint256 maxRewardPerVote,
        uint256 totalRewardAmount,
        uint256 feeAmount,
        QuestDataTypes.QuestVoteType voteType,
        QuestDataTypes.QuestCloseType closeType,
        address[] calldata voterList
    ) external nonReentrant isAlive isInitialized returns(uint256) {
        // Set the Quest Types for the new Quest
        QuestTypes memory types = QuestTypes({
            voteType: voteType,
            rewardsType: QuestDataTypes.QuestRewardsType.RANGE,
            closeType: closeType
        });

        return _createQuest(
            gauge,
            rewardToken,
            types,
            startNextPeriod,
            duration,
            minRewardPerVote,
            maxRewardPerVote,
            totalRewardAmount,
            feeAmount,
            voterList
        );
    }

    /**
    * @notice Creates a Quest based on the given parameters
    * @dev Creates a Quest based on the given parameters & the given types
    * @param gauge Address of the gauge
    * @param rewardToken Address of the reward token
    * @param types Quest Types (Rewards, Vote & Close)
    * @param startNextPeriod (bool) true to start the Quest the next period
    * @param duration Duration of the Quest (in weeks)
    * @param minRewardPerVote Minimum amount of reward/vote (in wei)
    * @param maxRewardPerVote Maximum amount of reward/vote (in wei)
    * @param totalRewardAmount Total amount of rewards available for the full Quest duration
    * @param feeAmount Amount of fees paid at creation
    * @param voterList List of voters for the Quest (to be used for Blacklist or Whitelist)
    * @return newQuestID (uint256) : ID of the newly created Quest
    */
    function _createQuest(
        address gauge,
        address rewardToken,
        QuestTypes memory types,
        bool startNextPeriod,
        uint48 duration,
        uint256 minRewardPerVote,
        uint256 maxRewardPerVote,
        uint256 totalRewardAmount,
        uint256 feeAmount,
        address[] calldata voterList
    ) internal returns(uint256 newQuestID) {
        // Local memory variables
        CreateVars memory vars;
        vars.creator = msg.sender;

        // Check all parameters
        if(gauge == address(0) || rewardToken == address(0)) revert Errors.AddressZero();
        if(IGaugeController(GAUGE_CONTROLLER).gauge_types(gauge) < 0) revert Errors.InvalidGauge();
        if(!whitelistedTokens[rewardToken]) revert Errors.TokenNotWhitelisted();
        if(duration == 0) revert Errors.IncorrectDuration();
        if(minRewardPerVote == 0 || maxRewardPerVote == 0 || totalRewardAmount == 0 || feeAmount == 0) revert Errors.NullAmount();
        if(minRewardPerVote < minRewardPerVotePerToken[rewardToken]) revert Errors.RewardPerVoteTooLow();
        if(minRewardPerVote > maxRewardPerVote) revert Errors.MinValueOverMaxValue();
        if(types.rewardsType == QuestDataTypes.QuestRewardsType.FIXED && minRewardPerVote != maxRewardPerVote) revert Errors.InvalidQuestType();
        if((totalRewardAmount * _getFeeRatio(msg.sender))/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        // Calculate the reward per period, and the max vote objective per period
        vars.rewardPerPeriod = totalRewardAmount / duration;
        vars.maxObjective = (vars.rewardPerPeriod * UNIT) / minRewardPerVote;

        // And based on the Quest Rewards type, calculate the min vote objective per period
        if(types.rewardsType == QuestDataTypes.QuestRewardsType.RANGE) {
            // For a Ranged Quest, calculate it based on the max reward per vote
            vars.minObjective = (vars.rewardPerPeriod * UNIT) / maxRewardPerVote;
        } else {
            // Otherwise, min == max
            vars.minObjective = vars.maxObjective;
        }

        if(vars.minObjective < objectiveMinimalThreshold) revert Errors.ObjectiveTooLow();

        // Pull all the rewards in this contract
        IERC20(rewardToken).safeTransferFrom(vars.creator, address(this), totalRewardAmount);
        // And transfer the fees from the Quest creator to the Chest contract
        IERC20(rewardToken).safeTransferFrom(vars.creator, questChest, feeAmount);

        // Get the period when the Quest starts (current or next period)
        vars.startPeriod = getCurrentPeriod();
        if(startNextPeriod) vars.startPeriod += WEEK;

        // Get the ID for that new Quest and increment the nextID counter
        newQuestID = nextID;
        unchecked{ ++nextID; }

        // Fill the Quest struct data
        quests[newQuestID].creator = vars.creator;
        quests[newQuestID].rewardToken = rewardToken;
        quests[newQuestID].gauge = gauge;
        quests[newQuestID].types = types;
        quests[newQuestID].duration = duration;
        quests[newQuestID].totalRewardAmount = totalRewardAmount;
        quests[newQuestID].periodStart = safe48(vars.startPeriod);

        //Set the current Distributor as the one to receive the rewards for users for that Quest
        questDistributors[newQuestID] = distributor;

        // Iterate on periods based on Quest duration
        vars.periodIterator = vars.startPeriod;
        for(uint256 i; i < duration;){
            // Add the Quest on the list of Quests active on the period
            questsByPeriod[vars.periodIterator].push(newQuestID);
            questsByGaugeByPeriod[gauge][vars.periodIterator].push(newQuestID);

            // And add the period in the list of periods of the Quest
            questPeriods[newQuestID].push(safe48(vars.periodIterator));

            periodsByQuest[newQuestID][vars.periodIterator].periodStart = safe48(vars.periodIterator);
            periodsByQuest[newQuestID][vars.periodIterator].minObjectiveVotes = vars.minObjective;
            periodsByQuest[newQuestID][vars.periodIterator].maxObjectiveVotes = vars.maxObjective;
            periodsByQuest[newQuestID][vars.periodIterator].minRewardPerVote = minRewardPerVote;
            periodsByQuest[newQuestID][vars.periodIterator].maxRewardPerVote = maxRewardPerVote;
            periodsByQuest[newQuestID][vars.periodIterator].rewardAmountPerPeriod = vars.rewardPerPeriod;
            periodsByQuest[newQuestID][vars.periodIterator].currentState = QuestDataTypes.PeriodState.ACTIVE;

            vars.periodIterator = ((vars.periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        if(voterList.length > 0) {
            // Set the voterlist for this Quest
            BiasCalculator(biasCalculator).setQuestVoterList(newQuestID, voterList);
        }

        if(types.closeType == QuestDataTypes.QuestCloseType.DISTRIBUTE){
            // Check if the Board is allowed to distribute rewards to the gauge
            // If not, we want to revert and the creator to chose another Close type
            if(IGauge(gauge).reward_data(rewardToken).distributor != address(this)) revert Errors.BoardIsNotAllowedDistributor();
        }

        // Add that Quest & the reward token in the Distributor
        if(!MultiMerkleDistributor(distributor).addQuest(newQuestID, rewardToken)) revert Errors.DisitributorFail();

        emit NewQuest(
            newQuestID,
            msg.sender,
            gauge,
            rewardToken,
            duration,
            vars.startPeriod
        );
    }

    /**
    * @notice Increases the duration of a Quest
    * @dev Adds more QuestPeriods and extends the duration of a Quest
    * @param questID ID of the Quest
    * @param addedDuration Number of period to add
    * @param addedRewardAmount Amount of reward to add for the new periods (in wei)
    * @param feeAmount Platform fees amount (in wei)
    */
    function extendQuestDuration(
        uint256 questID,
        uint48 addedDuration,
        uint256 addedRewardAmount,
        uint256 feeAmount
    ) external nonReentrant isAlive isInitialized {
        // Local memory variables
        ExtendVars memory vars;

        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(addedRewardAmount == 0 || feeAmount == 0) revert Errors.NullAmount();
        if(addedDuration == 0) revert Errors.IncorrectAddDuration();

        // We take data from the last period of the Quest to account for any other changes in the Quest parameters
        if(questPeriods[questID].length == 0) revert Errors.EmptyQuest();
        vars.lastPeriod = questPeriods[questID][questPeriods[questID].length - 1];
        
        if(periodsByQuest[questID][questPeriods[questID][0]].periodStart >= block.timestamp) revert Errors.QuestNotStarted();
        if(vars.lastPeriod < getCurrentPeriod()) revert Errors.ExpiredQuest();

        // Check that the given amounts are correct
        vars.rewardPerPeriod = periodsByQuest[questID][vars.lastPeriod].rewardAmountPerPeriod;

        if((vars.rewardPerPeriod * addedDuration) != addedRewardAmount) revert Errors.IncorrectAddedRewardAmount();
        if((addedRewardAmount * _getFeeRatio(msg.sender))/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        vars.gauge = quests[questID].gauge;
        vars.rewardToken = quests[questID].rewardToken;
        // Pull all the rewards in this contract
        IERC20(vars.rewardToken).safeTransferFrom(msg.sender, address(this), addedRewardAmount);
        // And transfer the fees from the Quest creator to the Chest contract
        IERC20(vars.rewardToken).safeTransferFrom(msg.sender, questChest, feeAmount);

        vars.periodIterator = ((vars.lastPeriod + WEEK) / WEEK) * WEEK;

        // Update the Quest struct with added reward admounts & added duration
        quests[questID].totalRewardAmount += addedRewardAmount;
        quests[questID].duration += addedDuration;

        vars.minObjective = periodsByQuest[questID][vars.lastPeriod].minObjectiveVotes;
        vars.maxObjective = periodsByQuest[questID][vars.lastPeriod].maxObjectiveVotes;
        vars.minRewardPerVote = periodsByQuest[questID][vars.lastPeriod].minRewardPerVote;
        vars.maxRewardPerVote = periodsByQuest[questID][vars.lastPeriod].maxRewardPerVote;

        // Add QuestPeriods for the new added duration
        for(uint256 i; i < addedDuration;){
            questsByPeriod[vars.periodIterator].push(questID);
            questsByGaugeByPeriod[quests[questID].gauge][vars.periodIterator].push(questID);

            questPeriods[questID].push(safe48(vars.periodIterator));

            periodsByQuest[questID][vars.periodIterator].periodStart = safe48(vars.periodIterator);
            periodsByQuest[questID][vars.periodIterator].minObjectiveVotes = vars.minObjective;
            periodsByQuest[questID][vars.periodIterator].maxObjectiveVotes = vars.maxObjective;
            periodsByQuest[questID][vars.periodIterator].minRewardPerVote = vars.minRewardPerVote;
            periodsByQuest[questID][vars.periodIterator].maxRewardPerVote = vars.maxRewardPerVote;
            periodsByQuest[questID][vars.periodIterator].rewardAmountPerPeriod = vars.rewardPerPeriod;
            periodsByQuest[questID][vars.periodIterator].currentState = QuestDataTypes.PeriodState.ACTIVE;
            vars.periodIterator = ((vars.periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        emit ExtendQuestDuration(questID, addedDuration, addedRewardAmount);

    }
      
    /**
    * @notice Updates the parametes of the Quest
    * @dev Updates the reward/vote parameters, allowing to update the Quest objectives too
    * @param questID ID of the Quest
    * @param newMinRewardPerVote New min reward/vote value (in wei)
    * @param newMaxRewardPerVote New max reward/vote value (in wei)
    * @param addedPeriodRewardAmount Amount of reward to add for each period (in wei)
    * @param addedTotalRewardAmount Amount of reward to add for all periods (in wei)
    * @param feeAmount Platform fees amount (in wei)
    */
    function updateQuestParameters(
        uint256 questID,
        uint256 newMinRewardPerVote,
        uint256 newMaxRewardPerVote,
        uint256 addedPeriodRewardAmount,
        uint256 addedTotalRewardAmount,
        uint256 feeAmount
    ) external nonReentrant isAlive isInitialized {
        // Local memory variables
        UpdateVars memory vars;

        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(newMinRewardPerVote == 0 || newMaxRewardPerVote == 0) revert Errors.NullAmount();
        if(newMinRewardPerVote > newMaxRewardPerVote) revert Errors.MinValueOverMaxValue();
        if(quests[questID].types.rewardsType == QuestDataTypes.QuestRewardsType.FIXED && newMinRewardPerVote != newMaxRewardPerVote) revert Errors.InvalidQuestType();

        // Check the reamining duration, and that the given reward amounts are correct
        vars.remainingDuration = _getRemainingDuration(questID); //Also handles the Empty Quest check
        if(vars.remainingDuration == 0) revert Errors.ExpiredQuest();
        if(periodsByQuest[questID][questPeriods[questID][0]].periodStart >= block.timestamp) revert Errors.QuestNotStarted();
        if((addedPeriodRewardAmount * vars.remainingDuration) != addedTotalRewardAmount) revert Errors.IncorrectAddedRewardAmount();
        if((addedTotalRewardAmount * _getFeeRatio(msg.sender))/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        // The new min reward amount must be higher 
        vars.currentPeriod = getCurrentPeriod();
        if(newMinRewardPerVote < periodsByQuest[questID][vars.currentPeriod].minRewardPerVote) revert Errors.LowerRewardPerVote();

        // Get the amount of reward for each period
        vars.newRewardPerPeriod = periodsByQuest[questID][vars.currentPeriod].rewardAmountPerPeriod + addedPeriodRewardAmount;

        // Calculate the new max vote objective, and the min vote objective based on the Quest Rewards type
        vars.newMaxObjective = (vars.newRewardPerPeriod * UNIT) / newMinRewardPerVote;
        vars.newMinObjective;
        if(quests[questID].types.rewardsType == QuestDataTypes.QuestRewardsType.RANGE) {
            vars.newMinObjective = (vars.newRewardPerPeriod * UNIT) / newMaxRewardPerVote;
        } else {
            vars.newMinObjective = vars.newMaxObjective;
        }
        
        if(
            vars.newMinObjective < periodsByQuest[questID][vars.currentPeriod].minObjectiveVotes
        ) revert Errors.NewObjectiveTooLow();

        if(addedTotalRewardAmount > 0) {
            address rewardToken = quests[questID].rewardToken;
            // Pull all the rewards in this contract
            IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), addedTotalRewardAmount);
            // And transfer the fees from the Quest creator to the Chest contract
            IERC20(rewardToken).safeTransferFrom(msg.sender, questChest, feeAmount);
        }

        vars.periodIterator = vars.currentPeriod;

        vars.lastPeriod = questPeriods[questID][questPeriods[questID].length - 1];

        // Update the Quest struct with the added reward amount
        quests[questID].totalRewardAmount += addedTotalRewardAmount;

        // Update all QuestPeriods, starting with the currentPeriod one
        for(uint256 i; i < vars.remainingDuration;){

            if(vars.periodIterator > vars.lastPeriod) break; //Safety check, we never want to write on non-initialized QuestPeriods (that were not initialized)

            // And update each QuestPeriod with the new values
            periodsByQuest[questID][vars.periodIterator].minRewardPerVote = newMinRewardPerVote;
            periodsByQuest[questID][vars.periodIterator].maxRewardPerVote = newMaxRewardPerVote;
            periodsByQuest[questID][vars.periodIterator].minObjectiveVotes = vars.newMinObjective;
            periodsByQuest[questID][vars.periodIterator].maxObjectiveVotes = vars.newMaxObjective;
            periodsByQuest[questID][vars.periodIterator].rewardAmountPerPeriod = vars.newRewardPerPeriod;

            vars.periodIterator = ((vars.periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        emit UpdateQuestParameters(
            questID,
            vars.currentPeriod,
            newMinRewardPerVote,
            newMaxRewardPerVote,
            addedPeriodRewardAmount
        );
    }
   
    /**
    * @notice Withdraw all undistributed rewards from Closed Quest Periods
    * @dev Withdraw all undistributed rewards from Closed Quest Periods
    * @param questID ID of the Quest
    * @param recipient Address to send the reward tokens to
    */
    function withdrawUnusedRewards(uint256 questID, address recipient) external nonReentrant isAlive isInitialized {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(recipient == address(0)) revert Errors.AddressZero();

        // Total amount available to withdraw
        uint256 withdrawAmount = questWithdrawableAmount[questID];
        questWithdrawableAmount[questID] = 0;

        // If there is a non null amount of token to withdraw, execute a transfer
        if(withdrawAmount != 0){
            address rewardToken = quests[questID].rewardToken;
            IERC20(rewardToken).safeTransfer(recipient, withdrawAmount);

            emit WithdrawUnusedRewards(questID, recipient, withdrawAmount);
        }
    }
   
    /**
    * @notice Emergency withdraws all undistributed rewards from Closed Quest Periods & all rewards for Active Periods
    * @dev Emergency withdraws all undistributed rewards from Closed Quest Periods & all rewards for Active Periods
    * @param questID ID of the Quest
    * @param recipient Address to send the reward tokens to
    */
    function emergencyWithdraw(uint256 questID, address recipient) external nonReentrant {
        if(!isKilled) revert Errors.NotKilled();
        if(block.timestamp < killTs + KILL_DELAY) revert Errors.KillDelayNotExpired();

        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(recipient == address(0)) revert Errors.AddressZero();

        // Total amount to emergency withdraw
        uint256 withdrawAmount = questWithdrawableAmount[questID];
        questWithdrawableAmount[questID] = 0;

        uint48[] memory _questPeriods = questPeriods[questID];
        uint256 length = _questPeriods.length;
        for(uint256 i; i < length;){
            QuestPeriod storage _questPeriod = periodsByQuest[questID][_questPeriods[i]];

            // For ACTIVE periods
            if(_questPeriod.currentState == QuestDataTypes.PeriodState.ACTIVE){
                // For the active period, and the next ones, withdraw the total reward amount
                withdrawAmount += _questPeriod.rewardAmountPerPeriod;
                _questPeriod.rewardAmountPerPeriod = 0;
            }

            unchecked{ ++i; }
        }

        // If the total amount to emergency withdraw is non_null, execute a transfer
        if(withdrawAmount != 0){
            IERC20(quests[questID].rewardToken).safeTransfer(recipient, withdrawAmount);

            emit EmergencyWithdraw(questID, recipient, withdrawAmount);
        }

    }

    /**
    * @notice Get the fee ratio for a given Quest creator
    * @dev Returns the custom fee ratio for a Quest creator if set, otherwise returns the general fee ratio
    * @param questCreator address of the Quest creator
    * @return uint256 : fee ratio
    */
    function _getFeeRatio(address questCreator) internal view returns(uint256) {
        return customPlatformFeeRatio[questCreator] != 0 ? customPlatformFeeRatio[questCreator] : platformFeeRatio;
    }


    // Manager functions

    /**
    * @notice Gets the amount of rewards to be distributed for the period
    * @dev Gets the amount of rewards to be distributed for the
    * @param questRewardType Rewards type for the Quest
    * @param periodBias Bias of the gauge (reduced if nedded) for the given period
    * @param _questPeriod Data for the Quest Period
    * @return uint256 : Amount to be distributed
    */
    function _getDistributionAmount(
        QuestDataTypes.QuestRewardsType questRewardType,
        uint256 periodBias,
        QuestPeriod memory _questPeriod
    ) internal pure returns(uint256) {
        // Here, if the Gauge Bias is equal or greater than the objective, 
        // set all the period reward to be distributed.
        // If the bias is less, we take that bias, and calculate the amount of rewards based
        // on the rewardPerVote & the Gauge bias

        // If the votes received exceed the max objective of the Quest (for both types)
        // Distribute all the rewards for the period
        if(periodBias >= _questPeriod.maxObjectiveVotes) return _questPeriod.rewardAmountPerPeriod;

        if(questRewardType == QuestDataTypes.QuestRewardsType.FIXED) {
            return (periodBias * _questPeriod.minRewardPerVote) / UNIT;
        } else { // For QuestDataTypes.QuestRewardsType.RANGE
                // If the bias is under the minimum objective, use max reward/vote
            if(periodBias <= _questPeriod.minObjectiveVotes) return (periodBias * _questPeriod.maxRewardPerVote) / UNIT;
            else return _questPeriod.rewardAmountPerPeriod;
        }
    }

    /**
    * @notice Handles the Quest period undistributed rewards
    * @dev Handles the Quest period undistributed rewards based on the Quest Close type
    * @param questID ID of the Quest
    * @param currentPeriod Timestamp of the current period
    * @param questCloseType Close type for the Quest
    * @param rewardToken Address of the reward token
    * @param undistributedAmount Amount of token not distributed for voter rewards
    */
    function _handleUndistributedRewards(
        uint256 questID,
        uint256 currentPeriod,
        QuestDataTypes.QuestCloseType questCloseType,
        address rewardToken,
        uint256 undistributedAmount
    ) internal {
        if(undistributedAmount == 0) return;

        if(questCloseType == QuestDataTypes.QuestCloseType.ROLLOVER) {
            // Since this type is only allowed for FIXED Rewards Quests
            // We simply recalculate the next period reward/vote based on the current Objective
            uint256 nextPeriod = currentPeriod + WEEK;
            // If not the last period
            if(nextPeriod > questPeriods[questID][questPeriods[questID].length - 1]) {
                // This the Quest last period, no period to rollover to
                questWithdrawableAmount[questID] += undistributedAmount;
                return;
            }
            QuestPeriod storage _nextPeriod = periodsByQuest[questID][nextPeriod];

            // Calculate the new period parameters by adding undistributed rewards to the base period reward amount
            // & update the next period parameters based on new calculated parameters
            uint256 newRewardPerPeriod = _nextPeriod.rewardAmountPerPeriod + undistributedAmount;
            uint256 newMinRewardPerVote = (newRewardPerPeriod * UNIT) / _nextPeriod.maxObjectiveVotes;
            uint256 newMaxRewardPerVote = (newRewardPerPeriod * UNIT) / _nextPeriod.minObjectiveVotes;
            _nextPeriod.minRewardPerVote = newMinRewardPerVote;
            _nextPeriod.maxRewardPerVote = newMaxRewardPerVote;
            _nextPeriod.rewardAmountPerPeriod = newRewardPerPeriod;

            emit RewardsRollover(questID, newRewardPerPeriod, newMinRewardPerVote, newMaxRewardPerVote);
            
        } else if(questCloseType == QuestDataTypes.QuestCloseType.DISTRIBUTE) {
            address gauge = quests[questID].gauge;
            if(IGauge(gauge).reward_data(rewardToken).distributor == address(this)) {
                // Give allowance to the Gauge for distribution
                IERC20(rewardToken).safeApprove(gauge, undistributedAmount);
                // The QuestBoard should have given allowance to the Gauge at the Quest creation
                IGauge(gauge).deposit_reward_token(rewardToken, undistributedAmount);
            } else {
                // The Quest Board is not allowed to distribute the rewards, set them to be withdrawable
                questWithdrawableAmount[questID] += undistributedAmount;
            }
        } else { // For QuestDataTypes.QuestCloseType.NORMAL
            questWithdrawableAmount[questID] += undistributedAmount;
        }
    }

    /**
    * @notice Closes the Period, and all QuestPeriods for this period
    * @dev Closes all QuestPeriod for the given period, calculating rewards to distribute & send them to distributor
    * @param period Timestamp of the period
    */
    function _closeQuestPeriod(uint256 period, uint256 questID) internal returns(bool) {
        // We check that this period was not already closed
        if(periodsByQuest[questID][period].currentState != QuestDataTypes.PeriodState.ACTIVE) return false;

        IGaugeController gaugeController = IGaugeController(GAUGE_CONTROLLER);

        Quest memory _quest = quests[questID];
        QuestPeriod storage _questPeriod = periodsByQuest[questID][period];
        _questPeriod.currentState = QuestDataTypes.PeriodState.CLOSED;

        // Call a checkpoint on the Gauge, in case it was not written yet
        gaugeController.checkpoint_gauge(_quest.gauge);

        // Get the bias of the Gauge for the end of the period
        uint256 periodAdjustedBias = BiasCalculator(biasCalculator).getReducedBias(
            period + WEEK,
            questID,
            _quest.gauge,
            _quest.types.voteType
        );

        uint256 undistributedAmount;

        if(periodAdjustedBias == 0) { 
            // Because we don't want to divide by 0 here since the bias is 0, we consider 0% completion
            // => no rewards to be distributed
            // We do not change _questPeriod.rewardAmountDistributed since the default value is already 0
            undistributedAmount = _questPeriod.rewardAmountPerPeriod;
        }
        else{
            // Get the amount of rewards to be distributed
            uint256 distributionAmount = _getDistributionAmount(_quest.types.rewardsType, periodAdjustedBias, _questPeriod);
            _questPeriod.rewardAmountDistributed = distributionAmount;

            // And the rest is set as withdrawable amount, that the Quest creator can retrieve
            undistributedAmount = _questPeriod.rewardAmountPerPeriod - distributionAmount;

            // Send the rewards to be distributed to the Distrubutor
            address questDistributor = questDistributors[questID];
            if(!MultiMerkleDistributor(questDistributor).addQuestPeriod(questID, period, distributionAmount)) revert Errors.DisitributorFail();
            IERC20(_quest.rewardToken).safeTransfer(questDistributor, distributionAmount);
        }

        // Handle the undistributed rewards based on the Quest Close type
        _handleUndistributedRewards(questID, period, _quest.types.closeType, _quest.rewardToken, undistributedAmount);

        emit PeriodClosed(questID, period);

        return true;
    }
 
    /**
    * @notice Closes the Period, and all QuestPeriods for this period
    * @dev Closes all QuestPeriod for the given period, calculating rewards to distribute & send them to distributor
    * @param period Timestamp of the period
    */
    function closeQuestPeriod(uint256 period) external nonReentrant isAlive isInitialized onlyAllowed returns(uint256 closed, uint256 skipped) {
        period = (period / WEEK) * WEEK;
        if(period == 0) revert Errors.InvalidPeriod();
        if(period >= getCurrentPeriod()) revert Errors.PeriodStillActive();
        if(questsByPeriod[period].length == 0) revert Errors.EmptyPeriod();

        uint256[] memory questsForPeriod = questsByPeriod[period];

        // For each QuestPeriod
        uint256 length = questsForPeriod.length;
        for(uint256 i = 0; i < length;){
            bool result = _closeQuestPeriod(period, questsForPeriod[i]);

            if(result) closed++; 
            else skipped++;

            unchecked{ ++i; }
        }
    }

    /**
    * @notice Closes the given QuestPeriods for the Period
    * @dev Closes the given QuestPeriods for the Period, calculating rewards to distribute & send them to distributor
    * @param period Timestamp of the period
    * @param questIDs List of the Quest IDs to close
    */
    function closePartOfQuestPeriod(uint256 period, uint256[] calldata questIDs) external nonReentrant isAlive isInitialized onlyAllowed returns(uint256 closed, uint256 skipped) {
        period = (period / WEEK) * WEEK;
        uint256 questIDLength = questIDs.length;
        if(questIDLength == 0) revert Errors.EmptyArray();
        if(period == 0) revert Errors.InvalidPeriod();
        if(period >= getCurrentPeriod()) revert Errors.PeriodStillActive();
        if(questsByPeriod[period].length == 0) revert Errors.EmptyPeriod();

        // For each QuestPeriod for the given Quest IDs list
        for(uint256 i = 0; i < questIDLength;){
            bool result = _closeQuestPeriod(period, questIDs[i]);

            if(result) closed++; 
            else skipped++;

            unchecked{ ++i; }
        }
    }
   
    /**
    * @dev Sets the QuestPeriod as disitrbuted, and adds the MerkleRoot to the Distributor contract
    * @param questID ID of the Quest
    * @param period Timestamp of the period
    * @param totalAmount sum of all rewards for the Merkle Tree
    * @param merkleRoot MerkleRoot to add
    */
    function _addMerkleRoot(uint256 questID, uint256 period, uint256 totalAmount, bytes32 merkleRoot) internal {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(merkleRoot == 0) revert Errors.EmptyMerkleRoot();
        if(totalAmount == 0) revert Errors.NullAmount();

        // This also allows to check if the given period is correct => If not, the currentState is never set to CLOSED for the QuestPeriod
        if(periodsByQuest[questID][period].currentState != QuestDataTypes.PeriodState.CLOSED) revert Errors.PeriodNotClosed();

        // Add the MerkleRoot to the Distributor & set the QuestPeriod as DISTRIBUTED
        if(!MultiMerkleDistributor(questDistributors[questID]).updateQuestPeriod(questID, period, totalAmount, merkleRoot)) revert Errors.DisitributorFail();

        periodsByQuest[questID][period].currentState = QuestDataTypes.PeriodState.DISTRIBUTED;
    }
   
    /**
    * @notice Sets the QuestPeriod as disitrbuted, and adds the MerkleRoot to the Distributor contract
    * @dev internal call to _addMerkleRoot()
    * @param questID ID of the Quest
    * @param period Timestamp of the period
    * @param totalAmount sum of all rewards for the Merkle Tree
    * @param merkleRoot MerkleRoot to add
    */
    function addMerkleRoot(uint256 questID, uint256 period, uint256 totalAmount, bytes32 merkleRoot) external nonReentrant isAlive isInitialized onlyAllowed {
        period = (period / WEEK) * WEEK;
        _addMerkleRoot(questID, period, totalAmount, merkleRoot);
    }

    /**
    * @notice Sets a list of QuestPeriods as disitrbuted, and adds the MerkleRoot to the Distributor contract for each
    * @dev Loop and internal call to _addMerkleRoot()
    * @param questIDs List of Quest IDs
    * @param period Timestamp of the period
    * @param totalAmounts List of sums of all rewards for the Merkle Tree
    * @param merkleRoots List of MerkleRoots to add
    */
    function addMultipleMerkleRoot(
        uint256[] calldata questIDs,
        uint256 period,
        uint256[] calldata totalAmounts,
        bytes32[] calldata merkleRoots
    ) external nonReentrant isAlive isInitialized onlyAllowed {
        period = (period / WEEK) * WEEK;
        uint256 length = questIDs.length;

        if(length != merkleRoots.length) revert Errors.InequalArraySizes();
        if(length != totalAmounts.length) revert Errors.InequalArraySizes();

        for(uint256 i = 0; i < length;){
            _addMerkleRoot(questIDs[i], period, totalAmounts[i], merkleRoots[i]);

            unchecked{ ++i; }
        }
    }
   
    /**
    * @notice Whitelists a reward token
    * @dev Whitelists a reward token
    * @param newToken Address of the reward token
    * @param minRewardPerVote Minimal threshold of reward per vote for the reward token
    */
    function whitelistToken(address newToken, uint256 minRewardPerVote) public onlyAllowed {
        if(newToken == address(0)) revert Errors.AddressZero();
        if(minRewardPerVote == 0) revert Errors.InvalidParameter();

        whitelistedTokens[newToken] = true;

        minRewardPerVotePerToken[newToken] = minRewardPerVote;

        emit WhitelistToken(newToken, minRewardPerVote);
    }
   
    /**
    * @notice Whitelists a list of reward tokens
    * @dev Whitelists a list of reward tokens
    * @param newTokens List of reward tokens addresses
    * @param minRewardPerVotes List of minimal threshold of reward per vote for the reward token
    */
    function whitelistMultipleTokens(address[] calldata newTokens, uint256[] calldata minRewardPerVotes) external onlyAllowed {
        uint256 length = newTokens.length;

        if(length == 0) revert Errors.EmptyArray();
        if(length != minRewardPerVotes.length) revert Errors.InequalArraySizes();

        for(uint256 i = 0; i < length;){
            whitelistToken(newTokens[i], minRewardPerVotes[i]);

            unchecked{ ++i; }
        }
    }
   
    /**
    * @notice Updates a reward token parameters
    * @dev Updates a reward token parameters
    * @param newToken Address of the reward token
    * @param newMinRewardPerVote New minimal threshold of reward per vote for the reward token
    */
    function updateRewardToken(address newToken, uint256 newMinRewardPerVote) external onlyAllowed {
        if(!whitelistedTokens[newToken]) revert Errors.TokenNotWhitelisted();
        if(newMinRewardPerVote == 0) revert Errors.InvalidParameter();

        minRewardPerVotePerToken[newToken] = newMinRewardPerVote;

        emit UpdateRewardToken(newToken, newMinRewardPerVote);
    }


    // Admin functions

   
    /**
    * @notice Approves a new address as manager 
    * @dev Approves a new address as manager
    * @param period Timestamp fo the period to fix
    * @param questID ID of the Quest
    * @param correctReducedBias Currect bias to be used for the Quest period
    */
    /*
        This method is needed for managers to force this contract, in case the reduced bias
        calculated for the Gauge is incorrect for the period to close.
        The following scenario can create a difference between the expected Gauge Bias & the one calculated:
        A voting address, listed in the Blacklist for the given Quest, is already voting for the target Gauge.
        Between the moment where the period is ended (Thursday 00:00 GMT) and the moment the closeQuestPeriod()
        method is called, and does the calculation for the Gauge Bias (and removes the blacklisted voter bias),
        the blacklisted voter changes its vote on the Gauge (by increasing it, or reducing it, or even removing it),
        allowing it to change its last VotedSlope for that Gauge, and causing our system not to account correctly
        for the Bias used for the voting period we are closing
        This method will then allow to send the correct reduced Bias for the Gauge for the given period,
        and calculate the rewards for that period correctly (and do the required reward token transfers)
    */
    function fixQuestPeriodBias(uint256 period, uint256 questID, uint256 correctReducedBias) external nonReentrant isAlive onlyOwner {
        period = (period / WEEK) * WEEK;
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(distributor == address(0)) revert Errors.NoDistributorSet();
        if(period == 0) revert Errors.InvalidPeriod();
        if(period > getCurrentPeriod()) revert Errors.InvalidPeriod();

        Quest memory _quest = quests[questID];
        QuestPeriod storage _questPeriod = periodsByQuest[questID][period];

        // This also allows to check if the given period is correct => If not, the currentState is never set to CLOSED for the QuestPeriod
        if(_questPeriod.currentState != QuestDataTypes.PeriodState.CLOSED) revert Errors.PeriodNotClosed();

        uint256 previousRewardAmountDistributed = _questPeriod.rewardAmountDistributed;
        uint256 previousWithdrawableAmount = _questPeriod.rewardAmountPerPeriod - previousRewardAmountDistributed;

        address questDistributor = questDistributors[questID];

        if(correctReducedBias == 0) { 
            // Set rewardAmountDistributed back to 0, get all rewards token back to the Board
            _questPeriod.rewardAmountDistributed = 0;

            if(!MultiMerkleDistributor(questDistributor).fixQuestPeriod(questID, period, 0)) revert Errors.DisitributorFail();

            if(_quest.types.closeType == QuestDataTypes.QuestCloseType.NORMAL) {
                questWithdrawableAmount[questID] = questWithdrawableAmount[questID] + _questPeriod.rewardAmountPerPeriod - previousWithdrawableAmount;
            } else {
                _handleUndistributedRewards(questID, period, _quest.types.closeType, _quest.rewardToken, previousRewardAmountDistributed);
            }
        }
        else{
            uint256 newToDistributeAmount = _getDistributionAmount(_quest.types.rewardsType, correctReducedBias, _questPeriod);

            _questPeriod.rewardAmountDistributed = newToDistributeAmount;

            // Fix the Period in the Distributor, and retrieve token in case too much was sent
            if(!MultiMerkleDistributor(questDistributor).fixQuestPeriod(questID, period, newToDistributeAmount)) revert Errors.DisitributorFail();

            if(_quest.types.closeType == QuestDataTypes.QuestCloseType.ROLLOVER) {
                // Since this type is only allowed for FIXED Rewards Quests
                // We simply recalculate the next period reward/vote based on the current Objective
                uint256 nextPeriod = period + WEEK;
                // If not the last period
                if(nextPeriod > questPeriods[questID][questPeriods[questID].length - 1]) {
                    // This the Quest last period, no period to rollover to
                    questWithdrawableAmount[questID] = questWithdrawableAmount[questID] + (_questPeriod.rewardAmountPerPeriod - newToDistributeAmount) - previousWithdrawableAmount;
                } else {
                    QuestPeriod storage _nextPeriod = periodsByQuest[questID][nextPeriod];

                    uint256 newRewardPerPeriod = newToDistributeAmount > previousRewardAmountDistributed ?
                        _nextPeriod.rewardAmountPerPeriod - (newToDistributeAmount - previousRewardAmountDistributed) :
                        _nextPeriod.rewardAmountPerPeriod + (previousRewardAmountDistributed - newToDistributeAmount);
                    uint256 newMinRewardPerVote = (newRewardPerPeriod * UNIT) / _nextPeriod.maxObjectiveVotes;
                    uint256 newMaxRewardPerVote = (newRewardPerPeriod * UNIT) / _nextPeriod.minObjectiveVotes;
                    
                    _nextPeriod.minRewardPerVote = newMinRewardPerVote;
                    _nextPeriod.maxRewardPerVote = newMaxRewardPerVote;
                    _nextPeriod.rewardAmountPerPeriod = newRewardPerPeriod;

                    emit RewardsRollover(questID, newRewardPerPeriod, newMinRewardPerVote, newMaxRewardPerVote);
                }

                if(newToDistributeAmount > previousRewardAmountDistributed){
                    uint256 missingAmount = newToDistributeAmount - previousRewardAmountDistributed;
                    IERC20(_quest.rewardToken).safeTransfer(questDistributor, missingAmount);
                }
                
            } else if(_quest.types.closeType == QuestDataTypes.QuestCloseType.DISTRIBUTE) {
                if(newToDistributeAmount > previousRewardAmountDistributed){
                    uint256 missingAmount = newToDistributeAmount - previousRewardAmountDistributed;

                    // Need to pull it, since it was already sent to the Gauge to be distributed
                    IERC20(_quest.rewardToken).safeTransferFrom(msg.sender, questDistributor, missingAmount);
                } else {
                    // Amount sent back by the Distributor
                    uint256 missingAmount = previousRewardAmountDistributed - newToDistributeAmount;
                    address gauge = _quest.gauge;
                    if(IGauge(gauge).reward_data(_quest.rewardToken).distributor == address(this)) {
                        // Give allowance to the Gauge for distribution
                        IERC20(_quest.rewardToken).safeApprove(gauge, missingAmount);
                        // The QuestBoard should have given allowance to the Gauge at the Quest creation
                        IGauge(gauge).deposit_reward_token(_quest.rewardToken, missingAmount);
                    } else {
                        // The Quest Board is not allowed to distribute the rewards, set them to be withdrawable
                        questWithdrawableAmount[questID] += missingAmount;
                    }
                }
                
            } else { // For QuestDataTypes.QuestCloseType.NORMAL
                questWithdrawableAmount[questID] = questWithdrawableAmount[questID] + (_questPeriod.rewardAmountPerPeriod - newToDistributeAmount) - previousWithdrawableAmount;

                if(newToDistributeAmount > previousRewardAmountDistributed){
                    uint256 missingAmount = newToDistributeAmount - previousRewardAmountDistributed;
                    IERC20(_quest.rewardToken).safeTransfer(questDistributor, missingAmount);
                }
            }
        }

        emit PeriodBiasFixed(period, questID, correctReducedBias);
    }
   
    /**
    * @notice Approves a new address as manager 
    * @dev Approves a new address as manager
    * @param newManager Address to add
    */
    function approveManager(address newManager) external onlyOwner {
        if(newManager == address(0)) revert Errors.AddressZero();
        approvedManagers[newManager] = true;

        emit ApprovedManager(newManager);
    }
   
    /**
    * @notice Removes an address from the managers
    * @dev Removes an address from the managers
    * @param manager Address to remove
    */
    function removeManager(address manager) external onlyOwner {
        if(manager == address(0)) revert Errors.AddressZero();
        approvedManagers[manager] = false;

        emit RemovedManager(manager);
    }
   
    /**
    * @notice Updates the Chest address
    * @dev Updates the Chest address
    * @param chest Address of the new Chest
    */
    function updateChest(address chest) external onlyOwner {
        if(chest == address(0)) revert Errors.AddressZero();
        address oldChest = questChest;
        questChest = chest;

        emit ChestUpdated(oldChest, chest);
    }
   
    /**
    * @notice Updates the Distributor address
    * @dev Updates the Distributor address
    * @param newDistributor Address of the new Distributor
    */
    function updateDistributor(address newDistributor) external onlyOwner {
        if(newDistributor == address(0)) revert Errors.AddressZero();
        address oldDistributor = distributor;
        distributor = newDistributor;

        emit DistributorUpdated(oldDistributor, distributor);
    }
   
    /**
    * @notice Updates the Platfrom fees BPS ratio
    * @dev Updates the Platfrom fees BPS ratio
    * @param newFee New fee ratio
    */
    function updatePlatformFee(uint256 newFee) external onlyOwner {
        if(newFee > 500) revert Errors.InvalidParameter();
        uint256 oldfee = platformFeeRatio;
        platformFeeRatio = newFee;

        emit PlatformFeeRatioUpdated(oldfee, newFee);
    }
   
    /**
    * @notice Updates the min objective value
    * @dev Updates the min objective value
    * @param newMinObjective New min objective
    */
    function updateMinObjective(uint256 newMinObjective) external onlyOwner {
        if(newMinObjective == 0) revert Errors.InvalidParameter();
        uint256 oldMinObjective = objectiveMinimalThreshold;
        objectiveMinimalThreshold = newMinObjective;

        emit MinObjectiveUpdated(oldMinObjective, newMinObjective);
    }
   
    /**
    * @notice Sets a custom fee ratio for a given address
    * @dev Sets a custom fee ratio for a given address
    * @param user User address
    * @param customFeeRatio Custom fee ratio
    */
    function setCustomFeeRatio(address user, uint256 customFeeRatio) external onlyOwner {
        if(customFeeRatio > platformFeeRatio) revert Errors.InvalidParameter();
        
        customPlatformFeeRatio[user] = customFeeRatio;

        emit SetCustomFeeRatio(user, customFeeRatio);
    }
   
    /**
    * @notice Recovers ERC2O tokens sent by mistake to the contract
    * @dev Recovers ERC2O tokens sent by mistake to the contract
    * @param token Address tof the EC2O token
    * @return bool: success
    */
    function recoverERC20(address token) external onlyOwner returns(bool) {
        if(whitelistedTokens[token]) revert Errors.CannotRecoverToken();

        uint256 amount = IERC20(token).balanceOf(address(this));
        if(amount == 0) revert Errors.NullAmount();
        IERC20(token).safeTransfer(owner(), amount);

        return true;
    }
   
    /**
    * @notice Kills the contract
    * @dev Kills the contract
    */
    function killBoard() external onlyOwner {
        if(isKilled) revert Errors.AlreadyKilled();
        isKilled = true;
        killTs = block.timestamp;

        emit Killed(killTs);
    }
   
    /**
    * @notice Unkills the contract
    * @dev Unkills the contract
    */
    function unkillBoard() external onlyOwner {
        if(!isKilled) revert Errors.NotKilled();
        if(block.timestamp >= killTs + KILL_DELAY) revert Errors.KillDelayExpired();
        isKilled = false;

        emit Unkilled(block.timestamp);
    }


    // Utils 

    function safe48(uint n) internal pure returns (uint48) {
        if(n > type(uint48).max) revert Errors.NumberExceed48Bits();
        return uint48(n);
    }

}