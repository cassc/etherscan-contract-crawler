//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
 

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./oz/interfaces/IERC20.sol";
import "./oz/libraries/SafeERC20.sol";
import "./utils/Owner.sol";
import "./oz/utils/ReentrancyGuard.sol";
import "./MultiMerkleDistributor.sol";
import "./interfaces/IGaugeController.sol";
import "./utils/Errors.sol";

/** @title Warden Quest Board  */
/// @author Paladin
/*
    Main contract, holding all the Quests data & ressources
    Allowing users to add/update Quests
    And the managers to update Quests to the next period & trigger the rewards for closed periods 
*/

contract QuestBoard is Owner, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /** @notice Address of the Curve Gauge Controller */
    address public immutable GAUGE_CONTROLLER;

    /** @notice Seconds in a Week */
    uint256 private constant WEEK = 604800;
    /** @notice 1e18 scale */
    uint256 private constant UNIT = 1e18;
    /** @notice Max BPS value (100%) */
    uint256 private constant MAX_BPS = 10000;


    /** @notice State of each Period for each Quest */
    enum PeriodState { ZERO, ACTIVE, CLOSED, DISTRIBUTED }
    // All Periods are ACTIVE at creation since they voters from past periods are also accounted for the future period


    /** @notice Struct for a Period of a Quest */
    struct QuestPeriod {
        // Total reward amount that can be distributed for that period
        uint256 rewardAmountPerPeriod;
        // Amount of reward for each vote (for 1 veCRV)
        uint256 rewardPerVote;
        // Tartget Bias for the Gauge
        uint256 objectiveVotes;
        // Amount of reward to distribute, at period closing
        uint256 rewardAmountDistributed;
        // Amount not distributed, for Quest creator to redeem
        uint256 withdrawableAmount;
        // Timestamp of the Period start
        uint48 periodStart;
        // Current state of the Period
        PeriodState currentState;
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
    }

    /** @notice ID for the next Quest to be created */
    uint256 public nextID;

    /** @notice List of Quest (indexed by ID) */
    // ID => Quest
    mapping(uint256 => Quest) public quests;
    /** @notice List of timestamp periods the Quest is active in */
    // QuestID => Periods (timestamps)
    mapping(uint256 => uint48[]) public questPeriods;
    /** @notice Mapping of all QuestPeriod struct for each period of each Quest */
    // QuestID => period => QuestPeriod
    mapping(uint256 => mapping(uint256 => QuestPeriod)) public periodsByQuest;
    /** @notice All the Quests present in this period */
    // period => array of Quest
    mapping(uint256 => uint256[]) public questsByPeriod;
    /** @notice Mapping of Distributors used by each Quest to send rewards */
    // ID => Distributor
    mapping(uint256 => address) public questDistributors;


    /** @notice Platform fees ratio (in BPS) */
    uint256 public platformFee = 400;

    /** @notice Minimum Objective required */
    uint256 public minObjective;

    /** @notice Address of the Chest to receive platform fees */
    address public questChest;
    /** @notice Address of the reward Distributor contract */
    address public distributor;

    /** @notice Mapping of addresses allowed to call manager methods */
    mapping(address => bool) approvedManagers;
    /** @notice Whitelisted tokens that can be used as reward tokens */
    mapping(address => bool) public whitelistedTokens;
    /** @notice Min rewardPerVote per token (to avoid spam creation of useless Quest) */
    mapping(address => uint256) public minRewardPerVotePerToken;

    /** @notice Boolean, true if the cotnract was killed, stopping main user functions */
    bool public isKilled;
    /** @notice Timestam pwhen the contract was killed */
    uint256 public kill_ts;
    /** @notice Delay where contract can be unkilled */
    uint256 public constant KILL_DELAY = 2 * 604800; //2 weeks

    // Events

    /** @notice Event emitted when a new Quest is created */
    event NewQuest(
        uint256 indexed questID,
        address indexed creator,
        address indexed gauge,
        address rewardToken,
        uint48 duration,
        uint256 startPeriod,
        uint256 objectiveVotes,
        uint256 rewardPerVote
    );

    /** @notice Event emitted when rewards of a Quest are increased */
    event IncreasedQuestReward(uint256 indexed questID, uint256 indexed updatePeriod, uint256 newRewardPerVote, uint256 addedRewardAmount);
    /** @notice Event emitted when the Quest objective bias is increased */
    event IncreasedQuestObjective(uint256 indexed questID, uint256 indexed updatePeriod, uint256 newObjective, uint256 addedRewardAmount);
    /** @notice Event emitted when the Quest duration is extended */
    event IncreasedQuestDuration(uint256 indexed questID, uint256 addedDuration, uint256 addedRewardAmount);

    /** @notice Event emitted when Quest creator withdraw undistributed rewards */
    event WithdrawUnusedRewards(uint256 indexed questID, address recipient, uint256 amount);

    /** @notice Event emitted when a Period is Closed */
    event PeriodClosed(uint256 indexed questID, uint256 indexed period);

    /** @notice Event emitted when a new reward token is whitelisted */
    event WhitelistToken(address indexed token, uint256 minRewardPerVote);
    event UpdateRewardToken(address indexed token, uint256 newMinRewardPerVote);

    /** @notice Event emitted when the contract is killed */
    event Killed(uint256 killTime);
    /** @notice Event emitted when the contract is unkilled */
    event Unkilled(uint256 unkillTime);
    /** @notice Event emitted when the Quest creator withdraw all unused funds (if the contract was killed) */
    event EmergencyWithdraw(uint256 indexed questID, address recipient, uint256 amount);

    event InitDistributor(address distributor);
    event ApprovedManager(address indexed manager);
    event RemovedManager(address indexed manager);
    event ChestUpdated(address oldChest, address newChest);
    event DistributorUpdated(address oldDistributor, address newDistributor);
    event PlatformFeeUpdated(uint256 oldfee, uint256 newFee);
    event MinObjectiveUpdated(uint256 oldMinObjective, uint256 newMinObjective);

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


    // Constructor
    constructor(address _gaugeController, address _chest){
        if(_gaugeController == address(0)) revert Errors.ZeroAddress();
        if(_chest == address(0)) revert Errors.ZeroAddress();
        if(_gaugeController == _chest) revert Errors.SameAddress();


        GAUGE_CONTROLLER = _gaugeController;

        questChest = _chest;

        minObjective = 1000 * UNIT;
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


    // Functions


    struct CreateVars {
        address creator;
        uint256 rewardPerPeriod;
        uint256 nextPeriod;
    }
   
    /**
    * @notice Creates a new Quest
    * @dev Creates a new Quest struct, and QuestPeriods for the Quest duration
    * @param gauge Address of the Gauge targeted by the Quest
    * @param rewardToken Address of the reward token
    * @param duration Duration (in number of periods) of the Quest
    * @param objective Target bias to reach (equivalent to amount of veCRV in wei to reach)
    * @param rewardPerVote Amount of reward per veCRV (in wei)
    * @param totalRewardAmount Total amount of rewards for the whole Quest (in wei)
    * @param feeAmount Platform fees amount (in wei)
    * @return uint256 : ID of the newly created Quest
    */
    function createQuest(
        address gauge,
        address rewardToken,
        uint48 duration,
        uint256 objective,
        uint256 rewardPerVote,
        uint256 totalRewardAmount,
        uint256 feeAmount
    ) external isAlive nonReentrant returns(uint256) {
        if(distributor == address(0)) revert Errors.NoDistributorSet();
        // Local memory variables
        CreateVars memory vars;
        vars.creator = msg.sender;

        // Check all parameters
        if(gauge == address(0) || rewardToken == address(0)) revert Errors.ZeroAddress();
        if(IGaugeController(GAUGE_CONTROLLER).gauge_types(gauge) < 0) revert Errors.InvalidGauge();
        if(!whitelistedTokens[rewardToken]) revert Errors.TokenNotWhitelisted();
        if(duration == 0) revert Errors.IncorrectDuration();
        if(objective < minObjective) revert Errors.ObjectiveTooLow();
        if(rewardPerVote == 0 || totalRewardAmount == 0 || feeAmount == 0) revert Errors.NullAmount();
        if(rewardPerVote < minRewardPerVotePerToken[rewardToken]) revert Errors.RewardPerVoteTooLow();

        // Verifiy the given amounts of reward token are correct
        vars.rewardPerPeriod = (objective * rewardPerVote) / UNIT;

        if((vars.rewardPerPeriod * duration) != totalRewardAmount) revert Errors.IncorrectTotalRewardAmount();
        if((totalRewardAmount * platformFee)/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        // Pull all the rewards in this contract
        IERC20(rewardToken).safeTransferFrom(vars.creator, address(this), totalRewardAmount);
        // And transfer the fees from the Quest creator to the Chest contract
        IERC20(rewardToken).safeTransferFrom(vars.creator, questChest, feeAmount);

        // Quest will start on next period
        vars.nextPeriod = getCurrentPeriod() + WEEK;

        // Get the ID for that new Quest and increment the nextID counter
        uint256 newQuestID = nextID;
        unchecked{ ++nextID; }

        // Fill the Quest struct data
        quests[newQuestID].creator = vars.creator;
        quests[newQuestID].rewardToken = rewardToken;
        quests[newQuestID].gauge = gauge;
        quests[newQuestID].duration = duration;
        quests[newQuestID].totalRewardAmount = totalRewardAmount;
        quests[newQuestID].periodStart = safe48(vars.nextPeriod);

        uint48[] memory _periods = new uint48[](duration);

        //Set the current Distributor as the one to receive the rewards for users for that Quest
        questDistributors[newQuestID] = distributor;

        // Iterate on periods based on Quest duration
        uint256 periodIterator = vars.nextPeriod;
        for(uint256 i; i < duration;){
            // Add the Quest on the list of Quests active on the period
            questsByPeriod[periodIterator].push(newQuestID);

            // And add the period in the list of periods of the Quest
            _periods[i] = safe48(periodIterator);

            periodsByQuest[newQuestID][periodIterator].periodStart = safe48(periodIterator);
            periodsByQuest[newQuestID][periodIterator].objectiveVotes = objective;
            periodsByQuest[newQuestID][periodIterator].rewardPerVote = rewardPerVote;
            periodsByQuest[newQuestID][periodIterator].rewardAmountPerPeriod = vars.rewardPerPeriod;
            periodsByQuest[newQuestID][periodIterator].currentState = PeriodState.ACTIVE;
            // Rest of the struct shoud laready have the correct base data:
            // rewardAmountDistributed => 0
            // withdrawableAmount => 0

            periodIterator = ((periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        // Write the array of period timestamp of that Quest in storage
        questPeriods[newQuestID] = _periods;

        // Add that Quest & the reward token in the Distributor
        if(!MultiMerkleDistributor(distributor).addQuest(newQuestID, rewardToken)) revert Errors.DisitributorFail();

        emit NewQuest(
            newQuestID,
            vars.creator,
            gauge,
            rewardToken,
            duration,
            vars.nextPeriod,
            objective,
            rewardPerVote
        );

        return newQuestID;
    }

   
    /**
    * @notice Increases the duration of a Quest
    * @dev Adds more QuestPeriods and extends the duration of a Quest
    * @param questID ID of the Quest
    * @param addedDuration Number of period to add
    * @param addedRewardAmount Amount of reward to add for the new periods (in wei)
    * @param feeAmount Platform fees amount (in wei)
    */
    function increaseQuestDuration(
        uint256 questID,
        uint48 addedDuration,
        uint256 addedRewardAmount,
        uint256 feeAmount
    ) external isAlive nonReentrant {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(addedRewardAmount == 0 || feeAmount == 0) revert Errors.NullAmount();
        if(addedDuration == 0) revert Errors.IncorrectAddDuration();

        //We take data from the last period of the Quest to account for any other changes in the Quest parameters
        if(questPeriods[questID].length == 0) revert Errors.EmptyQuest();
        uint256 lastPeriod = questPeriods[questID][questPeriods[questID].length - 1];

        if(lastPeriod < getCurrentPeriod()) revert Errors.ExpiredQuest();

        // Check that the given amounts are correct
        uint rewardPerPeriod = periodsByQuest[questID][lastPeriod].rewardAmountPerPeriod;

        if((rewardPerPeriod * addedDuration) != addedRewardAmount) revert Errors.IncorrectAddedRewardAmount();
        if((addedRewardAmount * platformFee)/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        address rewardToken = quests[questID].rewardToken;
        // Pull all the rewards in this contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), addedRewardAmount);
        // And transfer the fees from the Quest creator to the Chest contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, questChest, feeAmount);

        uint256 periodIterator = ((lastPeriod + WEEK) / WEEK) * WEEK;

        // Update the Quest struct with added reward admounts & added duration
        quests[questID].totalRewardAmount += addedRewardAmount;
        quests[questID].duration += addedDuration;

        uint256 objective = periodsByQuest[questID][lastPeriod].objectiveVotes;
        uint256 rewardPerVote = periodsByQuest[questID][lastPeriod].rewardPerVote;

        // Add QuestPeriods for the new added duration
        for(uint256 i; i < addedDuration;){
            questsByPeriod[periodIterator].push(questID);

            questPeriods[questID].push(safe48(periodIterator));

            periodsByQuest[questID][periodIterator].periodStart = safe48(periodIterator);
            periodsByQuest[questID][periodIterator].objectiveVotes = objective;
            periodsByQuest[questID][periodIterator].rewardPerVote = rewardPerVote;
            periodsByQuest[questID][periodIterator].rewardAmountPerPeriod = rewardPerPeriod;
            periodsByQuest[questID][periodIterator].currentState = PeriodState.ACTIVE;
            // Rest of the struct shoud laready have the correct base data:
            // rewardAmountDistributed => 0
            // redeemableAmount => 0

            periodIterator = ((periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        emit IncreasedQuestDuration(questID, addedDuration, addedRewardAmount);

    }
   
    /**
    * @notice Increases the reward per votes for a Quest
    * @dev Increases the reward per votes for a Quest
    * @param questID ID of the Quest
    * @param newRewardPerVote New amount of reward per veCRV (in wei)
    * @param addedRewardAmount Amount of rewards to add (in wei)
    * @param feeAmount Platform fees amount (in wei)
    */
    function increaseQuestReward(
        uint256 questID,
        uint256 newRewardPerVote,
        uint256 addedRewardAmount,
        uint256 feeAmount
    ) external isAlive nonReentrant {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(newRewardPerVote == 0 || addedRewardAmount == 0 || feeAmount == 0) revert Errors.NullAmount();
    
        uint256 remainingDuration = _getRemainingDuration(questID); //Also handles the Empty Quest check
        if(remainingDuration == 0) revert Errors.ExpiredQuest();

        // The new reward amount must be higher 
        uint256 currentPeriod = getCurrentPeriod();
        if(newRewardPerVote <= periodsByQuest[questID][currentPeriod].rewardPerVote) revert Errors.LowerRewardPerVote();

        // For all non closed QuestPeriods
        // Calculates the amount of reward token needed with the new rewardPerVote value
        // by calculating the new amount of reward per period, and the difference with the current amount of reward per period
        // to have the exact amount to add for each non-closed period, and the exact total amount to add to the Quest
        // (because we don't want to pay for Periods that are Closed)
        uint256 newRewardPerPeriod = (periodsByQuest[questID][currentPeriod].objectiveVotes * newRewardPerVote) / UNIT;
        uint256 diffRewardPerPeriod = newRewardPerPeriod - periodsByQuest[questID][currentPeriod].rewardAmountPerPeriod;

        if((diffRewardPerPeriod * remainingDuration) != addedRewardAmount) revert Errors.IncorrectAddedRewardAmount();
        if((addedRewardAmount * platformFee)/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        address rewardToken = quests[questID].rewardToken;
        // Pull all the rewards in this contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), addedRewardAmount);
        // And transfer the fees from the Quest creator to the Chest contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, questChest, feeAmount);

        uint256 periodIterator = currentPeriod;

        uint256 lastPeriod = questPeriods[questID][questPeriods[questID].length - 1];

        // Update the Quest struct with the added reward amount
        quests[questID].totalRewardAmount += addedRewardAmount;

        // Update all QuestPeriods, starting with the currentPeriod one
        for(uint256 i; i < remainingDuration;){

            if(periodIterator > lastPeriod) break; //Safety check, we never want to write on non-initialized QuestPeriods (that were not initialized)

            // And update each QuestPeriod with the new values
            periodsByQuest[questID][periodIterator].rewardPerVote = newRewardPerVote;
            periodsByQuest[questID][periodIterator].rewardAmountPerPeriod = newRewardPerPeriod;

            periodIterator = ((periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        emit IncreasedQuestReward(questID, currentPeriod, newRewardPerVote, addedRewardAmount);
    }
   
    /**
    * @notice Increases the target bias/veCRV amount to reach on the Gauge
    * @dev CIncreases the target bias/veCRV amount to reach on the Gauge
    * @param questID ID of the Quest
    * @param newObjective New target bias to reach (equivalent to amount of veCRV in wei to reach)
    * @param addedRewardAmount Amount of rewards to add (in wei)
    * @param feeAmount Platform fees amount (in wei)
    */
    function increaseQuestObjective(
        uint256 questID,
        uint256 newObjective,
        uint256 addedRewardAmount,
        uint256 feeAmount
    ) external isAlive nonReentrant {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(addedRewardAmount == 0 || feeAmount == 0) revert Errors.NullAmount();
    
        uint256 remainingDuration = _getRemainingDuration(questID); //Also handles the Empty Quest check
        if(remainingDuration == 0) revert Errors.ExpiredQuest();

        // No need to compare to minObjective : the new value must be higher than current Objective
        // and current objective needs to be >= minObjective
        uint256 currentPeriod = getCurrentPeriod();
        if(newObjective <= periodsByQuest[questID][currentPeriod].objectiveVotes) revert Errors.LowerObjective();

        // For all non closed QuestPeriods
        // Calculates the amount of reward token needed with the new objective bias
        // by calculating the new amount of reward per period, and the difference with the current amount of reward per period
        // to have the exact amount to add for each non-closed period, and the exact total amount to add to the Quest
        // (because we don't want to pay for Periods that are Closed)
        uint256 newRewardPerPeriod = (newObjective * periodsByQuest[questID][currentPeriod].rewardPerVote) / UNIT;
        uint256 diffRewardPerPeriod = newRewardPerPeriod - periodsByQuest[questID][currentPeriod].rewardAmountPerPeriod;

        if((diffRewardPerPeriod * remainingDuration) != addedRewardAmount) revert Errors.IncorrectAddedRewardAmount();
        if((addedRewardAmount * platformFee)/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        address rewardToken = quests[questID].rewardToken;
        // Pull all the rewards in this contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), addedRewardAmount);
        // And transfer the fees from the Quest creator to the Chest contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, questChest, feeAmount);


        uint256 periodIterator = currentPeriod;

        uint256 lastPeriod = questPeriods[questID][questPeriods[questID].length - 1];

        // Update the Quest struct with the added reward amount
        quests[questID].totalRewardAmount += addedRewardAmount;

        // Update all QuestPeriods, starting with the currentPeriod one
        for(uint256 i; i < remainingDuration;){

            if(periodIterator > lastPeriod) break; //Safety check, we never want to write on non-existing QuestPeriods (that were not initialized)

            // And update each QuestPeriod with the new values
            periodsByQuest[questID][periodIterator].objectiveVotes = newObjective;
            periodsByQuest[questID][periodIterator].rewardAmountPerPeriod = newRewardPerPeriod;

            periodIterator = ((periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        emit IncreasedQuestObjective(questID, currentPeriod, newObjective, addedRewardAmount);
    }
   
    /**
    * @notice Withdraw all undistributed rewards from Closed Quest Periods
    * @dev Withdraw all undistributed rewards from Closed Quest Periods
    * @param questID ID of the Quest
    * @param recipient Address to send the reward tokens to
    */
    function withdrawUnusedRewards(uint256 questID, address recipient) external isAlive nonReentrant {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(recipient == address(0)) revert Errors.ZeroAddress();

        // Total amount available to withdraw
        uint256 totalWithdraw;

        uint48[] memory _questPeriods = questPeriods[questID];

        uint256 length = _questPeriods.length;
        for(uint256 i; i < length;){
            QuestPeriod storage _questPeriod = periodsByQuest[questID][_questPeriods[i]];

            // We allow to withdraw unused rewards after the period was closed, or after it was distributed
            if(_questPeriod.currentState == PeriodState.ACTIVE) {
                unchecked{ ++i; }
                continue;
            }

            uint256 withdrawableForPeriod = _questPeriod.withdrawableAmount;

            // If there is token to withdraw for that period, add they to the total to withdraw,
            // and set the withdrawable amount to 0
            if(withdrawableForPeriod != 0){
                totalWithdraw += withdrawableForPeriod;
                _questPeriod.withdrawableAmount = 0;
            }

            unchecked{ ++i; }
        }

        // If there is a non null amount of token to withdraw, execute a transfer
        if(totalWithdraw != 0){
            address rewardToken = quests[questID].rewardToken;
            IERC20(rewardToken).safeTransfer(recipient, totalWithdraw);

            emit WithdrawUnusedRewards(questID, recipient, totalWithdraw);
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
        if(block.timestamp < kill_ts + KILL_DELAY) revert Errors.KillDelayNotExpired();

        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(recipient == address(0)) revert Errors.ZeroAddress();

        // Total amount to emergency withdraw
        uint256 totalWithdraw;

        uint48[] memory _questPeriods = questPeriods[questID];
        uint256 length = _questPeriods.length;
        for(uint256 i; i < length;){
            QuestPeriod storage _questPeriod = periodsByQuest[questID][_questPeriods[i]];

            // For CLOSED or DISTRIBUTED periods
            if(_questPeriod.currentState != PeriodState.ACTIVE){
                uint256 withdrawableForPeriod = _questPeriod.withdrawableAmount;

                // If there is a non_null withdrawable amount for the period,
                // add it to the total to withdraw, et set the withdrawable amount ot 0
                if(withdrawableForPeriod != 0){
                    totalWithdraw += withdrawableForPeriod;
                    _questPeriod.withdrawableAmount = 0;
                }
            } else {
                // And for the active period, and the next ones, withdraw the total reward amount
                totalWithdraw += _questPeriod.rewardAmountPerPeriod;
                _questPeriod.rewardAmountPerPeriod = 0;
            }

            unchecked{ ++i; }
        }

        // If the total amount to emergency withdraw is non_null, execute a transfer
        if(totalWithdraw != 0){
            address rewardToken = quests[questID].rewardToken;
            IERC20(rewardToken).safeTransfer(recipient, totalWithdraw);

            emit EmergencyWithdraw(questID, recipient, totalWithdraw);
        }

    }



    // Manager functions

    function _closeQuestPeriod(uint256 period, uint256 questID) internal returns(bool) {
        // We check that this period was not already closed
        if(periodsByQuest[questID][period].currentState != PeriodState.ACTIVE) return false;
            
        // We use the Gauge Point data from nextPeriod => the end of the period we are closing
        uint256 nextPeriod = period + WEEK;

        IGaugeController gaugeController = IGaugeController(GAUGE_CONTROLLER);

        Quest memory _quest = quests[questID];
        QuestPeriod memory _questPeriod = periodsByQuest[questID][period];
        _questPeriod.currentState = PeriodState.CLOSED;

        // Call a checkpoint on the Gauge, in case it was not written yet
        gaugeController.checkpoint_gauge(_quest.gauge);

        // Get the bias of the Gauge for the end of the period
        uint256 periodBias = gaugeController.points_weight(_quest.gauge, nextPeriod).bias;

        if(periodBias == 0) { 
            //Because we don't want to divide by 0
            // Here since the bias is 0, we consider 0% completion
            // => no rewards to be distributed
            // We do not change _questPeriod.rewardAmountDistributed since the default value is already 0
            _questPeriod.withdrawableAmount = _questPeriod.rewardAmountPerPeriod;
        }
        else{
            // For here, if the Gauge Bias is equal or greater than the objective, 
            // set all the period reward to be distributed.
            // If the bias is less, we take that bias, and calculate the amount of rewards based
            // on the rewardPerVote & the Gauge bias

            uint256 toDistributeAmount = periodBias >= _questPeriod.objectiveVotes ? _questPeriod.rewardAmountPerPeriod : (periodBias * _questPeriod.rewardPerVote) / UNIT;

            _questPeriod.rewardAmountDistributed = toDistributeAmount;
            // And the rest is set as withdrawable amount, that the Quest creator can retrieve
            _questPeriod.withdrawableAmount = _questPeriod.rewardAmountPerPeriod - toDistributeAmount;

            address questDistributor = questDistributors[questID];
            if(!MultiMerkleDistributor(questDistributor).addQuestPeriod(questID, period, toDistributeAmount)) revert Errors.DisitributorFail();
            IERC20(_quest.rewardToken).safeTransfer(questDistributor, toDistributeAmount);
        }

        periodsByQuest[questID][period] =  _questPeriod;

        emit PeriodClosed(questID, period);

        return true;
    }
 
    /**
    * @notice Closes the Period, and all QuestPeriods for this period
    * @dev Closes all QuestPeriod for the given period, calculating rewards to distribute & send them to distributor
    * @param period Timestamp of the period
    */
    function closeQuestPeriod(uint256 period) external isAlive onlyAllowed nonReentrant returns(uint256 closed, uint256 skipped) {
        period = (period / WEEK) * WEEK;
        if(distributor == address(0)) revert Errors.NoDistributorSet();
        if(period == 0) revert Errors.InvalidPeriod();
        if(period >= getCurrentPeriod()) revert Errors.PeriodStillActive();
        if(questsByPeriod[period].length == 0) revert Errors.EmptyPeriod();
        // We use the 1st QuestPeriod of this period to check it was not Closed
        uint256[] memory questsForPeriod = questsByPeriod[period];

        // For each QuestPeriod
        uint256 length = questsForPeriod.length;
        for(uint256 i = 0; i < length;){
            bool result = _closeQuestPeriod(period, questsForPeriod[i]);

            if(result){
                closed++;
            } 
            else {
                skipped++;
            }

            unchecked{ ++i; }
        }
    }

    /**
    * @notice Closes the given QuestPeriods for the Period
    * @dev Closes the given QuestPeriods for the Period, calculating rewards to distribute & send them to distributor
    * @param period Timestamp of the period
    * @param questIDs List of the Quest IDs to close
    */
    function closePartOfQuestPeriod(uint256 period, uint256[] calldata questIDs) external isAlive onlyAllowed nonReentrant returns(uint256 closed, uint256 skipped) {
        period = (period / WEEK) * WEEK;
        uint256 questIDLength = questIDs.length;
        if(questIDLength == 0) revert Errors.EmptyArray();
        if(distributor == address(0)) revert Errors.NoDistributorSet();
        if(period == 0) revert Errors.InvalidPeriod();
        if(period >= getCurrentPeriod()) revert Errors.PeriodStillActive();
        if(questsByPeriod[period].length == 0) revert Errors.EmptyPeriod();

        // For each QuestPeriod
        for(uint256 i = 0; i < questIDLength;){
            bool result = _closeQuestPeriod(period, questIDs[i]);

            if(result){
                closed++;
            } 
            else {
                skipped++;
            }

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
        if(periodsByQuest[questID][period].currentState != PeriodState.CLOSED) revert Errors.PeriodNotClosed();

        // Add the MerkleRoot to the Distributor & set the QuestPeriod as DISTRIBUTED
        if(!MultiMerkleDistributor(questDistributors[questID]).updateQuestPeriod(questID, period, totalAmount, merkleRoot)) revert Errors.DisitributorFail();

        periodsByQuest[questID][period].currentState = PeriodState.DISTRIBUTED;
    }
   
    /**
    * @notice Sets the QuestPeriod as disitrbuted, and adds the MerkleRoot to the Distributor contract
    * @dev internal call to _addMerkleRoot()
    * @param questID ID of the Quest
    * @param period Timestamp of the period
    * @param totalAmount sum of all rewards for the Merkle Tree
    * @param merkleRoot MerkleRoot to add
    */
    function addMerkleRoot(uint256 questID, uint256 period, uint256 totalAmount, bytes32 merkleRoot) external isAlive onlyAllowed nonReentrant {
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
    ) external isAlive onlyAllowed nonReentrant {
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
    */
    function whitelistToken(address newToken, uint256 minRewardPerVote) public onlyAllowed {
        if(newToken == address(0)) revert Errors.ZeroAddress();
        if(minRewardPerVote == 0) revert Errors.InvalidParameter();

        whitelistedTokens[newToken] = true;

        minRewardPerVotePerToken[newToken] = minRewardPerVote;

        emit WhitelistToken(newToken, minRewardPerVote);
    }
   
    /**
    * @notice Whitelists a list of reward tokens
    * @dev Whitelists a list of reward tokens
    * @param newTokens List of reward tokens addresses
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

    function updateRewardToken(address newToken, uint256 newMinRewardPerVote) external onlyAllowed {
        if(!whitelistedTokens[newToken]) revert Errors.TokenNotWhitelisted();
        if(newMinRewardPerVote == 0) revert Errors.InvalidParameter();

        minRewardPerVotePerToken[newToken] = newMinRewardPerVote;

        emit UpdateRewardToken(newToken, newMinRewardPerVote);
    }

    // Admin functions
   
    /**
    * @notice Sets an initial Distributor address
    * @dev Sets an initial Distributor address
    * @param newDistributor Address of the Distributor
    */
    function initiateDistributor(address newDistributor) external onlyOwner {
        if(distributor != address(0)) revert Errors.AlreadyInitialized();
        distributor = newDistributor;

        emit InitDistributor(newDistributor);
    }
   
    /**
    * @notice Approves a new address as manager 
    * @dev Approves a new address as manager
    * @param newManager Address to add
    */
    function approveManager(address newManager) external onlyOwner {
        if(newManager == address(0)) revert Errors.ZeroAddress();
        approvedManagers[newManager] = true;

        emit ApprovedManager(newManager);
    }
   
    /**
    * @notice Removes an address from the managers
    * @dev Removes an address from the managers
    * @param manager Address to remove
    */
    function removeManager(address manager) external onlyOwner {
        if(manager == address(0)) revert Errors.ZeroAddress();
        approvedManagers[manager] = false;

        emit RemovedManager(manager);
    }
   
    /**
    * @notice Updates the Chest address
    * @dev Updates the Chest address
    * @param chest Address of the new Chest
    */
    function updateChest(address chest) external onlyOwner {
        if(chest == address(0)) revert Errors.ZeroAddress();
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
        if(newDistributor == address(0)) revert Errors.ZeroAddress();
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
        uint256 oldfee = platformFee;
        platformFee = newFee;

        emit PlatformFeeUpdated(oldfee, newFee);
    }
   
    /**
    * @notice Updates the min objective value
    * @dev Updates the min objective value
    * @param newMinObjective New min objective
    */
    function updateMinObjective(uint256 newMinObjective) external onlyOwner {
        if(newMinObjective == 0) revert Errors.InvalidParameter();
        uint256 oldMinObjective = minObjective;
        minObjective = newMinObjective;

        emit MinObjectiveUpdated(oldMinObjective, newMinObjective);
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
        kill_ts = block.timestamp;

        emit Killed(kill_ts);
    }
   
    /**
    * @notice Unkills the contract
    * @dev Unkills the contract
    */
    function unkillBoard() external onlyOwner {
        if(!isKilled) revert Errors.NotKilled();
        if(block.timestamp >= kill_ts + KILL_DELAY) revert Errors.KillDelayExpired();
        isKilled = false;

        emit Unkilled(block.timestamp);
    }



    // Utils 

    function safe48(uint n) internal pure returns (uint48) {
        if(n > type(uint48).max) revert Errors.NumberExceed48Bits();
        return uint48(n);
    }

}