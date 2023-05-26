// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;
/*
▄▄▄█████▓ ██░ ██ ▓█████     ██░ ██ ▓█████  ██▀███  ▓█████▄ 
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▓██░ ██▒▓█   ▀ ▓██ ▒ ██▒▒██▀ ██▌
▒ ▓██░ ▒░▒██▀▀██░▒███      ▒██▀▀██░▒███   ▓██ ░▄█ ▒░██   █▌
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ░▓█ ░██ ▒▓█  ▄ ▒██▀▀█▄  ░▓█▄   ▌
  ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░▓█▒░██▓░▒████▒░██▓ ▒██▒░▒████▓ 
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ▒ ░░▒░▒░░ ▒░ ░░ ▒▓ ░▒▓░ ▒▒▓  ▒ 
    ░     ▒ ░▒░ ░ ░ ░  ░    ▒ ░▒░ ░ ░ ░  ░  ░▒ ░ ▒░ ░ ▒  ▒ 
  ░       ░  ░░ ░   ░       ░  ░░ ░   ░     ░░   ░  ░ ░  ░ 
          ░  ░  ░   ░  ░    ░  ░  ░   ░  ░   ░        ░    
                                                    ░      
              .,;>>%%%%%>>;,.
           .>%%%%%%%%%%%%%%%%%%%%>,.
         .>%%%%%%%%%%%%%%%%%%>>,%%%%%%;,.
       .>>>>%%%%%%%%%%%%%>>,%%%%%%%%%%%%,>>%%,.
     .>>%>>>>%%%%%%%%%>>,%%%%%%%%%%%%%%%%%,>>%%%%%,.
   .>>%%%%%>>%%%%>>,%%>>%%%%%%%%%%%%%%%%%%%%,>>%%%%%%%,
  .>>%%%%%%%%%%>>,%%%%%%>>%%%%%%%%%%%%%%%%%%,>>%%%%%%%%%%.
  .>>%%%%%%%%%%>>,>>>>%%%%%%%%%%'..`%%%%%%%%,;>>%%%%%%%%%>%%.
.>>%%%>>>%%%%%>,%%%%%%%%%%%%%%.%%%,`%%%%%%,;>>%%%%%%%%>>>%%%%.
>>%%>%>>>%>%%%>,%%%%%>>%%%%%%%%%%%%%`%%%%%%,>%%%%%%%>>>>%%%%%%%.
>>%>>>%%>>>%%%%>,%>>>%%%%%%%%%%%%%%%%`%%%%%%%%%%%%%%%%%%%%%%%%%%.
>>%%%%%%%%%%%%%%,>%%%%%%%%%%%%%%%%%%%'%%%,>>%%%%%%%%%%%%%%%%%%%%%.
>>%%%%%%%%%%%%%%%,>%%%>>>%%%%%%%%%%%%%%%,>>%%%%%%%%>>>>%%%%%%%%%%%.
>>%%%%%%%%;%;%;%%;,%>>>>%%%%%%%%%%%%%%%,>>>%%%%%%>>;";>>%%%%%%%%%%%%.
`>%%%%%%%%%;%;;;%;%,>%%%%%%%%%>>%%%%%%%%,>>>%%%%%%%%%%%%%%%%%%%%%%%%%%.
 >>%%%%%%%%%,;;;;;%%>,%%%%%%%%>>>>%%%%%%%%,>>%%%%%%%%%%%%%%%%%%%%%%%%%%%.
 `>>%%%%%%%%%,%;;;;%%%>,%%%%%%%%>>>>%%%%%%%%,>%%%%%%'%%%%%%%%%%%%%%%%%%%>>.
  `>>%%%%%%%%%%>,;;%%%%%>>,%%%%%%%%>>%%%%%%';;;>%%%%%,`%%%%%%%%%%%%%%%>>%%>.
   >>>%%%%%%%%%%>> %%%%%%%%>>,%%%%>>>%%%%%';;;;;;>>,%%%,`%     `;>%%%%%%>>%%
   `>>%%%%%%%%%%>> %%%%%%%%%>>>>>>>>;;;;'.;;;;;>>%%'  `%%'          ;>%%%%%>
    >>%%%%%%%%%>>; %%%%%%%%>>;;;;;;''    ;;;;;>>%%%                   ;>%%%%
    `>>%%%%%%%>>>, %%%%%%%%%>>;;'        ;;;;>>%%%'                    ;>%%%
     >>%%%%%%>>>':.%%%%%%%%%%>>;        .;;;>>%%%%                    ;>%%%'
     `>>%%%%%>>> ::`%%%%%%%%%%>>;.      ;;;>>%%%%'                   ;>%%%'
      `>>%%%%>>> `:::`%%%%%%%%%%>;.     ;;>>%%%%%                   ;>%%'
       `>>%%%%>>, `::::`%%%%%%%%%%>,   .;>>%%%%%'                   ;>%'
        `>>%%%%>>, `:::::`%%%%%%%%%>>. ;;>%%%%%%                    ;>%,
         `>>%%%%>>, :::::::`>>>%%%%>>> ;;>%%%%%'                     ;>%,
          `>>%%%%>>,::::::,>>>>>>>>>>' ;;>%%%%%                       ;%%,
            >>%%%%>>,:::,%%>>>>>>>>'   ;>%%%%%.                        ;%%
             >>%%%%>>``%%%%%>>>>>'     `>%%%%%%.
             >>%%%%>> `@@a%%%%%%'     .%%%%%%%%%.
             `[email protected]@a%@'    `%[email protected]@'       `[email protected]@a%[email protected]@a
 */

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {GaugeController} from "src/interfaces/GaugeController.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

/// version 2.0.0
/// @title  Platform
/// @author Stake DAO
contract Platform is Owned, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    ////////////////////////////////////////////////////////////////
    /// --- EMERGENCY SHUTDOWN
    ///////////////////////////////////////////////////////////////

    /// @notice Emergency shutdown flag
    bool public isKilled;

    ////////////////////////////////////////////////////////////////
    /// --- STRUCTS
    ///////////////////////////////////////////////////////////////

    /// @notice Bribe struct requirements.
    struct Bribe {
        // Address of the target gauge.
        address gauge;
        // Manager.
        address manager;
        // Address of the ERC20 used for rewards.
        address rewardToken;
        // Number of periods.
        uint8 numberOfPeriods;
        // Timestamp where the bribe become unclaimable.
        uint256 endTimestamp;
        // Max Price per vote.
        uint256 maxRewardPerVote;
        // Total Reward Added.
        uint256 totalRewardAmount;
        // Blacklisted addresses.
        address[] blacklist;
    }

    struct Upgrade {
        // Number of periods after increase.
        uint8 numberOfPeriods;
        // Total reward amount after increase.
        uint256 totalRewardAmount;
        // New max reward per vote after increase.
        uint256 maxRewardPerVote;
        // New end timestamp after increase.
        uint256 endTimestamp;
        // Blacklisted addresses.
        address[] blacklist;
    }

    /// @notice Period struct.
    struct Period {
        // Period id.
        // Eg: 0 is the first period, 1 is the second period, etc.
        uint8 id;
        // Timestamp of the period start.
        uint256 timestamp;
        // Reward amount distributed during the period.
        uint256 rewardPerPeriod;
    }

    ////////////////////////////////////////////////////////////////
    /// --- CONSTANTS & IMMUTABLES
    ///////////////////////////////////////////////////////////////

    /// @notice Minimum duration a Bribe.
    uint8 public constant MINIMUM_PERIOD = 2;

    /// @notice Week in seconds.
    uint256 private constant _WEEK = 1 weeks;

    /// @notice Base unit for fixed point compute.
    uint256 private constant _BASE_UNIT = 1e18;

    /// @notice Default fee.
    uint256 internal constant _DEFAULT_FEE = 2e16; // 2%

    /// @notice Gauge Controller.
    GaugeController public immutable gaugeController;

    ////////////////////////////////////////////////////////////////
    /// --- STORAGE VARS
    ///////////////////////////////////////////////////////////////

    /// @notice Fee.
    uint256 public fee;

    /// @notice Bribe ID Counter.
    uint256 public nextID;

    /// @notice Fee collector.
    address public feeCollector;

    /// @notice ID => Bribe.
    mapping(uint256 => Bribe) public bribes;

    /// @notice Recipient per address.
    mapping(address => address) public recipient;

    /// @notice Fee accrued per rewardToken.
    mapping(address => uint256) public feeAccrued;

    /// @notice BribeId => isUpgradeable. If true, the bribe can be upgraded.
    mapping(uint256 => bool) public isUpgradeable;

    /// @notice ID => Period running.
    mapping(uint256 => Period) public activePeriod;

    /// @notice ID => Amount Claimed per Bribe.
    mapping(uint256 => uint256) public amountClaimed;

    /// @notice ID => Amount of reward per vote distributed.
    mapping(uint256 => uint256) public rewardPerVote;

    /// @notice ID => Bribe In Queue to be upgraded.
    mapping(uint256 => Upgrade) public upgradeBribeQueue;

    /// @notice Blacklisted addresses per bribe that aren't counted for rewards arithmetics.
    mapping(uint256 => mapping(address => bool)) public isBlacklisted;

    /// @notice Last time a user claimed
    mapping(address => mapping(uint256 => uint256)) public lastUserClaim;

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier notKilled() {
        if (isKilled) revert KILLED();
        _;
    }

    modifier onlyManager(uint256 _id) {
        if (msg.sender != bribes[_id].manager) revert AUTH_MANAGER_ONLY();
        _;
    }

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS
    ///////////////////////////////////////////////////////////////

    /// @notice Emitted when a new bribe is created.
    /// @param id Bribe ID.
    /// @param gauge Gauge address.
    /// @param manager Manager address.
    /// @param rewardToken Reward token address.
    /// @param numberOfPeriods Number of periods.
    /// @param maxRewardPerVote Max reward per vote.
    /// @param rewardPerPeriod Reward per period.
    /// @param totalRewardAmount Total reward amount.
    /// @param isUpgradeable If true, the bribe can be upgraded.
    event BribeCreated(
        uint256 indexed id,
        address indexed gauge,
        address manager,
        address rewardToken,
        uint8 numberOfPeriods,
        uint256 maxRewardPerVote,
        uint256 rewardPerPeriod,
        uint256 totalRewardAmount,
        bool isUpgradeable
    );

    /// @notice Emitted when a bribe is closed.
    /// @param id Bribe ID.
    /// @param remainingReward Remaining reward.
    event BribeClosed(uint256 id, uint256 remainingReward);

    /// @notice Emitted when a bribe period is rolled over.
    /// @param id Bribe ID.
    /// @param periodId Period ID.
    /// @param timestamp Period timestamp.
    /// @param rewardPerPeriod Reward per period.
    event PeriodRolledOver(uint256 id, uint256 periodId, uint256 timestamp, uint256 rewardPerPeriod);

    /// @notice Emitted on claim.
    /// @param user User address.
    /// @param rewardToken Reward token address.
    /// @param bribeId Bribe ID.
    /// @param amount Amount claimed.
    /// @param protocolFees Protocol fees.
    /// @param period Period timestamp.
    event Claimed(
        address indexed user,
        address rewardToken,
        uint256 indexed bribeId,
        uint256 amount,
        uint256 protocolFees,
        uint256 period
    );

    /// @notice Emitted when a bribe is queued to upgrade.
    /// @param id Bribe ID.
    /// @param numberOfPeriods Number of periods.
    /// @param totalRewardAmount Total reward amount.
    /// @param maxRewardPerVote Max reward per vote.
    event BribeDurationIncreaseQueued(
        uint256 id, uint8 numberOfPeriods, uint256 totalRewardAmount, uint256 maxRewardPerVote
    );

    /// @notice Emitted when a bribe is upgraded.
    /// @param id Bribe ID.
    /// @param numberOfPeriods Number of periods.
    /// @param totalRewardAmount Total reward amount.
    /// @param maxRewardPerVote Max reward per vote.
    event BribeDurationIncreased(
        uint256 id, uint8 numberOfPeriods, uint256 totalRewardAmount, uint256 maxRewardPerVote
    );

    /// @notice Emitted when a bribe manager is updated.
    /// @param id Bribe ID.
    /// @param manager Manager address.
    event ManagerUpdated(uint256 id, address indexed manager);

    /// @notice Emitted when a recipient is set for an address.
    /// @param sender Sender address.
    /// @param recipient Recipient address.
    event RecipientSet(address indexed sender, address indexed recipient);

    /// @notice Emitted when fee is updated.
    /// @param fee Fee.
    event FeeUpdated(uint256 fee);

    /// @notice Emitted when fee collector is updated.
    /// @param feeCollector Fee collector.
    event FeeCollectorUpdated(address feeCollector);

    /// @notice Emitted when fees are collected.
    /// @param rewardToken Reward token address.
    /// @param amount Amount collected.
    event FeesCollected(address indexed rewardToken, uint256 amount);

    ////////////////////////////////////////////////////////////////
    /// --- ERRORS
    ///////////////////////////////////////////////////////////////

    error KILLED();
    error WRONG_INPUT();
    error ZERO_ADDRESS();
    error NO_PERIODS_LEFT();
    error NOT_UPGRADEABLE();
    error AUTH_MANAGER_ONLY();
    error INVALID_NUMBER_OF_PERIODS();

    ////////////////////////////////////////////////////////////////
    /// --- CONSTRUCTOR
    ///////////////////////////////////////////////////////////////

    /// @notice Create Bribe platform.
    /// @param _gaugeController Address of the gauge controller.
    constructor(address _gaugeController, address _feeCollector, address _owner) Owned(_owner) {
        fee = _DEFAULT_FEE;
        feeCollector = _feeCollector;
        gaugeController = GaugeController(_gaugeController);
    }

    ////////////////////////////////////////////////////////////////
    /// --- BRIBE CREATION LOGIC
    ///////////////////////////////////////////////////////////////

    /// @notice Create a new bribe.
    /// @param gauge Address of the target gauge.
    /// @param rewardToken Address of the ERC20 used or rewards.
    /// @param numberOfPeriods Number of periods.
    /// @param maxRewardPerVote Target Bias for the Gauge.
    /// @param totalRewardAmount Total Reward Added.
    /// @param blacklist Array of addresses to blacklist.
    /// @return newBribeID of the bribe created.
    function createBribe(
        address gauge,
        address manager,
        address rewardToken,
        uint8 numberOfPeriods,
        uint256 maxRewardPerVote,
        uint256 totalRewardAmount,
        address[] calldata blacklist,
        bool upgradeable
    ) external nonReentrant notKilled returns (uint256 newBribeID) {
        if (rewardToken == address(0)) revert ZERO_ADDRESS();
        if (gaugeController.gauge_types(gauge) < 0) return newBribeID;
        if (numberOfPeriods < MINIMUM_PERIOD) revert INVALID_NUMBER_OF_PERIODS();
        if (totalRewardAmount == 0 || maxRewardPerVote == 0) revert WRONG_INPUT();

        // Transfer the rewards to the contracts.
        SafeTransferLib.safeTransferFrom(rewardToken, msg.sender, address(this), totalRewardAmount);

        unchecked {
            // Get the ID for that new Bribe and increment the nextID counter.
            newBribeID = nextID;

            ++nextID;
        }

        uint256 rewardPerPeriod = totalRewardAmount.mulDiv(1, numberOfPeriods);
        uint256 currentPeriod = getCurrentPeriod();

        bribes[newBribeID] = Bribe({
            gauge: gauge,
            manager: manager,
            rewardToken: rewardToken,
            numberOfPeriods: numberOfPeriods,
            endTimestamp: currentPeriod + ((numberOfPeriods + 1) * _WEEK),
            maxRewardPerVote: maxRewardPerVote,
            totalRewardAmount: totalRewardAmount,
            blacklist: blacklist
        });

        emit BribeCreated(
            newBribeID,
            gauge,
            manager,
            rewardToken,
            numberOfPeriods,
            maxRewardPerVote,
            rewardPerPeriod,
            totalRewardAmount,
            upgradeable
        );

        // Set Upgradeable status.
        isUpgradeable[newBribeID] = upgradeable;
        // Starting from next period.
        activePeriod[newBribeID] = Period(0, currentPeriod + _WEEK, rewardPerPeriod);

        // Add the addresses to the blacklist.
        uint256 length = blacklist.length;
        for (uint256 i = 0; i < length;) {
            isBlacklisted[newBribeID][blacklist[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Claim rewards for a given bribe.
    /// @param bribeId ID of the bribe.
    /// @return Amount of rewards claimed.
    function claim(uint256 bribeId) external returns (uint256) {
        return _claim(msg.sender, msg.sender, bribeId);
    }

    /// @notice Claim rewards for a given bribe.
    /// @param bribeId ID of the bribe.
    /// @return Amount of rewards claimed.
    function claim(uint256 bribeId, address _recipient) external returns (uint256) {
        return _claim(msg.sender, _recipient, bribeId);
    }

    /// @notice Claim rewards for a given bribe.
    /// @param bribeId ID of the bribe.
    /// @return Amount of rewards claimed.
    function claimFor(address user, uint256 bribeId) external returns (uint256) {
        address _recipient = recipient[user];
        return _claim(user, _recipient != address(0) ? _recipient : user, bribeId);
    }

    /// @notice Claim all rewards for multiple bribes.
    /// @param ids Array of bribe IDs to claim.
    function claimAll(uint256[] calldata ids) external {
        uint256 length = ids.length;

        for (uint256 i = 0; i < length;) {
            uint256 id = ids[i];
            _claim(msg.sender, msg.sender, id);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Claim all rewards for multiple bribes to a given recipient.
    /// @param ids Array of bribe IDs to claim.
    /// @param _recipient Address to send the rewards to.
    function claimAll(uint256[] calldata ids, address _recipient) external {
        uint256 length = ids.length;

        for (uint256 i = 0; i < length;) {
            uint256 id = ids[i];
            _claim(msg.sender, _recipient, id);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Claim all rewards for multiple bribes on behalf of a user.
    /// @param ids Array of bribe IDs to claim.
    /// @param _user Address to claim the rewards for.
    function claimAllFor(address _user, uint256[] calldata ids) external {
        address _recipient = recipient[_user];
        uint256 length = ids.length;

        for (uint256 i = 0; i < length;) {
            uint256 id = ids[i];
            _claim(_user, _recipient != address(0) ? _recipient : _user, id);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Update Bribe for a given id.
    /// @param bribeId ID of the bribe.
    function updateBribePeriod(uint256 bribeId) external {
        _updateBribePeriod(bribeId);
    }

    /// @notice Update multiple bribes for given ids.
    /// @param ids Array of Bribe IDs.
    function updateBribePeriods(uint256[] calldata ids) external {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length;) {
            _updateBribePeriod(ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set a recipient address for calling user.
    /// @param _recipient Address of the recipient.
    /// @dev Recipient are used when calling claimFor functions. Regular claim functions will use msg.sender as recipient,
    ///  or recipient parameter provided if called by msg.sender.
    function setRecipient(address _recipient) external {
        recipient[msg.sender] = _recipient;

        emit RecipientSet(msg.sender, _recipient);
    }

    ////////////////////////////////////////////////////////////////
    /// --- INTERNAL LOGIC
    ///////////////////////////////////////////////////////////////

    /// @notice Claim rewards for a given bribe.
    /// @param _user Address of the user.
    /// @param _recipient Address of the recipient.
    /// @param _bribeId ID of the bribe.
    /// @return amount of rewards claimed.
    function _claim(address _user, address _recipient, uint256 _bribeId)
        internal
        nonReentrant
        notKilled
        returns (uint256 amount)
    {
        if (isBlacklisted[_bribeId][_user]) return 0;
        // Update if needed the current period.
        uint256 currentPeriod = _updateBribePeriod(_bribeId);

        Bribe storage bribe = bribes[_bribeId];

        // Get the last_vote timestamp.
        uint256 lastVote = gaugeController.last_user_vote(_user, bribe.gauge);

        GaugeController.VotedSlope memory userSlope = gaugeController.vote_user_slopes(_user, bribe.gauge);

        if (
            userSlope.slope == 0 || lastUserClaim[_user][_bribeId] >= currentPeriod || currentPeriod >= userSlope.end
                || currentPeriod <= lastVote || currentPeriod >= bribe.endTimestamp || currentPeriod != getCurrentPeriod()
                || amountClaimed[_bribeId] == bribe.totalRewardAmount
        ) return 0;

        // Update User last claim period.
        lastUserClaim[_user][_bribeId] = currentPeriod;

        // Voting Power = userSlope * dt
        // with dt = lock_end - period.
        uint256 _bias = _getAddrBias(userSlope.slope, userSlope.end, currentPeriod);
        // Compute the reward amount based on
        // Reward / Total Votes.
        amount = _bias.mulWad(rewardPerVote[_bribeId]);
        // Compute the reward amount based on
        // the max price to pay.
        uint256 _amountWithMaxPrice = _bias.mulWad(bribe.maxRewardPerVote);
        // Distribute the _min between the amount based on votes, and price.
        amount = FixedPointMathLib.min(amount, _amountWithMaxPrice);

        // Update the amount claimed.
        uint256 _amountClaimed = amountClaimed[_bribeId];

        if (amount + _amountClaimed > bribe.totalRewardAmount) {
            amount = bribe.totalRewardAmount - _amountClaimed;
        }

        amountClaimed[_bribeId] += amount;

        uint256 feeAmount;
        if (fee != 0) {
            feeAmount = amount.mulWad(fee);
            amount -= feeAmount;
            feeAccrued[bribe.rewardToken] += feeAmount;
        }

        // Transfer to user.
        SafeTransferLib.safeTransfer(bribe.rewardToken, _recipient, amount);

        emit Claimed(_user, bribe.rewardToken, _bribeId, amount, feeAmount, currentPeriod);
    }

    /// @notice Update the current period for a given bribe.
    /// @param bribeId Bribe ID.
    /// @return current/updated period.
    function _updateBribePeriod(uint256 bribeId) internal returns (uint256) {
        Period storage _activePeriod = activePeriod[bribeId];

        uint256 currentPeriod = getCurrentPeriod();

        if (_activePeriod.id == 0 && currentPeriod == _activePeriod.timestamp) {
            // Check if there is an upgrade in queue and update the bribe.
            _checkForUpgrade(bribeId);

            // Initialize reward per token.
            // Only for the first period, and if not already initialized.
            _updateRewardPerToken(bribeId, currentPeriod);
        }

        // Increase Period
        if (block.timestamp >= _activePeriod.timestamp + _WEEK) {
            // Checkpoint gauge to have up to date gauge weight.
            gaugeController.checkpoint_gauge(bribes[bribeId].gauge);

            // Check if there is an upgrade in queue and update the bribe.
            _checkForUpgrade(bribeId);

            // Roll to next period.
            _rollOverToNextPeriod(bribeId, currentPeriod);

            return currentPeriod;
        }

        return _activePeriod.timestamp;
    }

    /// @notice Checks for an upgrade and update the bribe.
    function _checkForUpgrade(uint256 bribeId) internal {
        Upgrade storage upgradedBribe = upgradeBribeQueue[bribeId];

        // Check if there is an upgrade in queue.
        if (upgradedBribe.totalRewardAmount != 0) {
            // Save new values.
            bribes[bribeId].endTimestamp = upgradedBribe.endTimestamp;
            bribes[bribeId].numberOfPeriods = upgradedBribe.numberOfPeriods;
            bribes[bribeId].maxRewardPerVote = upgradedBribe.maxRewardPerVote;
            bribes[bribeId].totalRewardAmount = upgradedBribe.totalRewardAmount;

            if (upgradedBribe.blacklist.length > 0) {
                bribes[bribeId].blacklist = upgradedBribe.blacklist;
            }

            emit BribeDurationIncreased(
                bribeId, upgradedBribe.numberOfPeriods, upgradedBribe.totalRewardAmount, upgradedBribe.maxRewardPerVote
            );

            // Reset the next values.
            delete upgradeBribeQueue[bribeId];
        }
    }

    /// @notice Roll over to next period.
    /// @param bribeId Bribe ID.
    /// @param currentPeriod Next period timestamp.
    function _rollOverToNextPeriod(uint256 bribeId, uint256 currentPeriod) internal {
        uint8 index = getActivePeriodPerBribe(bribeId);

        Bribe storage bribe = bribes[bribeId];

        uint256 periodsLeft = getPeriodsLeft(bribeId);
        uint256 rewardPerPeriod;

        rewardPerPeriod = bribe.totalRewardAmount - amountClaimed[bribeId];

        if (bribe.endTimestamp > currentPeriod + _WEEK && periodsLeft > 1) {
            rewardPerPeriod = rewardPerPeriod.mulDiv(1, periodsLeft);
        }

        // Get adjusted slope without blacklisted addresses.
        uint256 gaugeBias = _getAdjustedBias(bribe.gauge, bribe.blacklist, currentPeriod);

        rewardPerVote[bribeId] = rewardPerPeriod.mulDiv(_BASE_UNIT, gaugeBias);
        activePeriod[bribeId] = Period(index, currentPeriod, rewardPerPeriod);

        emit PeriodRolledOver(bribeId, index, currentPeriod, rewardPerPeriod);
    }

    /// @notice Update the amount of reward per token for a given bribe.
    /// @dev This function is only called once per Bribe.
    function _updateRewardPerToken(uint256 bribeId, uint256 currentPeriod) internal {
        if (rewardPerVote[bribeId] == 0) {
            Bribe storage bribe = bribes[bribeId];
            // Checkpoint gauge to have up to date gauge weight.
            gaugeController.checkpoint_gauge(bribe.gauge);

            uint256 gaugeBias = _getAdjustedBias(bribe.gauge, bribe.blacklist, currentPeriod);
            if (gaugeBias != 0) {
                rewardPerVote[bribeId] = activePeriod[bribeId].rewardPerPeriod.mulDiv(_BASE_UNIT, gaugeBias);
            }
        }
    }

    ////////////////////////////////////////////////////////////////
    /// ---  VIEWS
    ///////////////////////////////////////////////////////////////

    /// @notice Get an estimate of the reward amount for a given user.
    /// @param user Address of the user.
    /// @param bribeId ID of the bribe.
    /// @return amount of rewards.
    /// Mainly used for UI.
    function claimable(address user, uint256 bribeId) external view returns (uint256 amount) {
        if (isBlacklisted[bribeId][user]) return 0;

        Bribe memory bribe = bribes[bribeId];
        // If there is an upgrade in progress but period hasn't been rolled over yet.
        Upgrade storage upgradedBribe = upgradeBribeQueue[bribeId];

        // Update if needed the current period.
        uint256 currentPeriod = getCurrentPeriod();
        // End timestamp of the bribe.
        uint256 endTimestamp = FixedPointMathLib.max(bribe.endTimestamp, upgradedBribe.endTimestamp);
        // Get the last_vote timestamp.
        uint256 lastVote = gaugeController.last_user_vote(user, bribe.gauge);

        GaugeController.VotedSlope memory userSlope = gaugeController.vote_user_slopes(user, bribe.gauge);

        if (
            userSlope.slope == 0 || lastUserClaim[user][bribeId] >= currentPeriod || currentPeriod >= userSlope.end
                || currentPeriod <= lastVote || currentPeriod >= endTimestamp
                || currentPeriod < getActivePeriod(bribeId).timestamp || amountClaimed[bribeId] >= bribe.totalRewardAmount
        ) return 0;

        uint256 _rewardPerVote = rewardPerVote[bribeId];
        // If period updated.
        if (_rewardPerVote == 0 || (_rewardPerVote > 0 && getActivePeriod(bribeId).timestamp != currentPeriod)) {
            uint256 _rewardPerPeriod;

            if (upgradedBribe.numberOfPeriods != 0) {
                // Update max reward per vote.
                bribe.maxRewardPerVote = upgradedBribe.maxRewardPerVote;
                bribe.totalRewardAmount = upgradedBribe.totalRewardAmount;
            }

            uint256 periodsLeft = endTimestamp > currentPeriod ? (endTimestamp - currentPeriod) / _WEEK : 0;
            _rewardPerPeriod = bribe.totalRewardAmount - amountClaimed[bribeId];

            if (endTimestamp > currentPeriod + _WEEK && periodsLeft > 1) {
                _rewardPerPeriod = _rewardPerPeriod.mulDiv(1, periodsLeft);
            }

            // Get Adjusted Slope without blacklisted addresses weight.
            uint256 gaugeBias = _getAdjustedBias(bribe.gauge, bribe.blacklist, currentPeriod);
            _rewardPerVote = _rewardPerPeriod.mulDiv(_BASE_UNIT, gaugeBias);
        }
        // Get user voting power.
        uint256 _bias = _getAddrBias(userSlope.slope, userSlope.end, currentPeriod);
        // Estimation of the amount of rewards.
        amount = _bias.mulWad(_rewardPerVote);
        // Compute the reward amount based on
        // the max price to pay.
        uint256 _amountWithMaxPrice = _bias.mulWad(bribe.maxRewardPerVote);
        // Distribute the _min between the amount based on votes, and price.
        amount = FixedPointMathLib.min(amount, _amountWithMaxPrice);

        uint256 _amountClaimed = amountClaimed[bribeId];
        // Update the amount claimed.
        if (amount + _amountClaimed > bribe.totalRewardAmount) {
            amount = bribe.totalRewardAmount - _amountClaimed;
        }
        // Substract fees.
        if (fee != 0) {
            amount = amount.mulWad(_BASE_UNIT - fee);
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- INTERNAL VIEWS
    ///////////////////////////////////////////////////////////////

    /// @notice Get adjusted slope from Gauge Controller for a given gauge address.
    /// Remove the weight of blacklisted addresses.
    /// @param gauge Address of the gauge.
    /// @param _addressesBlacklisted Array of blacklisted addresses.
    /// @param period   Timestamp to check vote weight.
    function _getAdjustedBias(address gauge, address[] memory _addressesBlacklisted, uint256 period)
        internal
        view
        returns (uint256 gaugeBias)
    {
        // Cache the user slope.
        GaugeController.VotedSlope memory userSlope;
        // Bias
        uint256 _bias;
        // Last Vote
        uint256 _lastVote;
        // Cache the length of the array.
        uint256 length = _addressesBlacklisted.length;
        // Cache blacklist.
        // Get the gauge slope.
        gaugeBias = gaugeController.points_weight(gauge, period).bias;

        for (uint256 i = 0; i < length;) {
            // Get the user slope.
            userSlope = gaugeController.vote_user_slopes(_addressesBlacklisted[i], gauge);
            _lastVote = gaugeController.last_user_vote(_addressesBlacklisted[i], gauge);
            if (period > _lastVote) {
                _bias = _getAddrBias(userSlope.slope, userSlope.end, period);
                gaugeBias -= _bias;
            }
            // Increment i.
            unchecked {
                ++i;
            }
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- MANAGEMENT LOGIC
    ///////////////////////////////////////////////////////////////

    /// @notice Increase Bribe duration.
    /// @param _bribeId ID of the bribe.
    /// @param _additionnalPeriods Number of periods to add.
    /// @param _increasedAmount Total reward amount to add.
    /// @param _newMaxPricePerVote Total reward amount to add.
    function increaseBribeDuration(
        uint256 _bribeId,
        uint8 _additionnalPeriods,
        uint256 _increasedAmount,
        uint256 _newMaxPricePerVote,
        address[] calldata _addressesBlacklisted
    ) external nonReentrant notKilled onlyManager(_bribeId) {
        if (!isUpgradeable[_bribeId]) revert NOT_UPGRADEABLE();
        if (getPeriodsLeft(_bribeId) < 1) revert NO_PERIODS_LEFT();
        if (_increasedAmount == 0 || _newMaxPricePerVote == 0) {
            revert WRONG_INPUT();
        }

        Bribe storage bribe = bribes[_bribeId];
        Upgrade memory upgradedBribe = upgradeBribeQueue[_bribeId];

        SafeTransferLib.safeTransferFrom(bribe.rewardToken, msg.sender, address(this), _increasedAmount);

        if (upgradedBribe.totalRewardAmount != 0) {
            upgradedBribe = Upgrade({
                numberOfPeriods: upgradedBribe.numberOfPeriods + _additionnalPeriods,
                totalRewardAmount: upgradedBribe.totalRewardAmount + _increasedAmount,
                maxRewardPerVote: _newMaxPricePerVote,
                endTimestamp: upgradedBribe.endTimestamp + (_additionnalPeriods * _WEEK),
                blacklist: _addressesBlacklisted
            });
        } else {
            upgradedBribe = Upgrade({
                numberOfPeriods: bribe.numberOfPeriods + _additionnalPeriods,
                totalRewardAmount: bribe.totalRewardAmount + _increasedAmount,
                maxRewardPerVote: _newMaxPricePerVote,
                endTimestamp: bribe.endTimestamp + (_additionnalPeriods * _WEEK),
                blacklist: _addressesBlacklisted
            });
        }

        upgradeBribeQueue[_bribeId] = upgradedBribe;

        emit BribeDurationIncreaseQueued(
            _bribeId, upgradedBribe.numberOfPeriods, upgradedBribe.totalRewardAmount, _newMaxPricePerVote
        );
    }

    /// @notice Close Bribe if there is remaining.
    /// @param bribeId ID of the bribe to close.
    function closeBribe(uint256 bribeId) external nonReentrant onlyManager(bribeId) {
        // Check if the currentPeriod is the last one.
        // If not, we can increase the duration.
        Bribe storage bribe = bribes[bribeId];

        if (getCurrentPeriod() >= bribe.endTimestamp || isKilled) {
            uint256 leftOver;
            Upgrade memory upgradedBribe = upgradeBribeQueue[bribeId];
            if (upgradedBribe.totalRewardAmount != 0) {
                leftOver = upgradedBribe.totalRewardAmount - amountClaimed[bribeId];
                delete upgradeBribeQueue[bribeId];
            } else {
                leftOver = bribes[bribeId].totalRewardAmount - amountClaimed[bribeId];
            }
            // Transfer the left over to the owner.
            SafeTransferLib.safeTransfer(bribe.rewardToken, bribe.manager, leftOver);
            delete bribes[bribeId].manager;

            emit BribeClosed(bribeId, leftOver);
        }
    }

    /// @notice Update Bribe Manager.
    /// @param bribeId ID of the bribe.
    /// @param newManager Address of the new manager.
    function updateManager(uint256 bribeId, address newManager) external onlyManager(bribeId) {
        emit ManagerUpdated(bribeId, bribes[bribeId].manager = newManager);
    }

    ////////////////////////////////////////////////////////////////
    /// --- ONLY OWNER FUNCTIONS
    ///////////////////////////////////////////////////////////////

    /// @notice Claim fees.
    /// @param rewardTokens Array of reward tokens.
    function claimFees(address[] calldata rewardTokens) external onlyOwner {
        uint256 _feeAccrued;
        uint256 length = rewardTokens.length;

        for (uint256 i = 0; i < length;) {
            address rewardToken = rewardTokens[i];

            _feeAccrued = feeAccrued[rewardToken];
            delete feeAccrued[rewardToken];

            emit FeesCollected(rewardToken, _feeAccrued);

            SafeTransferLib.safeTransfer(rewardToken, feeCollector, _feeAccrued);

            unchecked {
                i++;
            }
        }
    }

    function kill() external onlyOwner {
        isKilled = true;
    }

    /// @notice Set the platform fee.
    /// @param _platformFee Platform fee.
    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        fee = _platformFee;

        emit FeeUpdated(_platformFee);
    }

    /// @notice Set the fee collector.
    /// @param _feeCollector Address of the fee collector.
    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;

        emit FeeCollectorUpdated(_feeCollector);
    }

    /// @notice Set the recipient for a given address.
    /// @param _for Address to set the recipient for.
    /// @param _recipient Address of the recipient.
    function setRecipientFor(address _for, address _recipient) external onlyOwner {
        recipient[_for] = _recipient;

        emit RecipientSet(_for, _recipient);
    }

    ////////////////////////////////////////////////////////////////
    /// --- UTILS FUNCTIONS
    ///////////////////////////////////////////////////////////////

    /// @notice Returns the number of periods left for a given bribe.
    /// @param bribeId ID of the bribe.
    function getPeriodsLeft(uint256 bribeId) public view returns (uint256 periodsLeft) {
        Bribe storage bribe = bribes[bribeId];

        uint256 currentPeriod = getCurrentPeriod();
        periodsLeft = bribe.endTimestamp > currentPeriod ? (bribe.endTimestamp - currentPeriod) / _WEEK : 0;
    }

    /// @notice Return the bribe object for a given ID.
    /// @param bribeId ID of the bribe.
    function getBribe(uint256 bribeId) external view returns (Bribe memory) {
        return bribes[bribeId];
    }

    /// @notice Return the bribe in queue for a given ID.
    /// @dev Can return an empty bribe if there is no upgrade.
    /// @param bribeId ID of the bribe.
    function getUpgradedBribeQueued(uint256 bribeId) external view returns (Upgrade memory) {
        return upgradeBribeQueue[bribeId];
    }

    /// @notice Return the blacklisted addresses of a bribe for a given ID.
    /// @param bribeId ID of the bribe.
    function getBlacklistedAddressesForBribe(uint256 bribeId) external view returns (address[] memory) {
        return bribes[bribeId].blacklist;
    }

    /// @notice Return the active period running of bribe given an ID.
    /// @param bribeId ID of the bribe.
    function getActivePeriod(uint256 bribeId) public view returns (Period memory) {
        return activePeriod[bribeId];
    }

    /// @notice Return the expected current period id.
    /// @param bribeId ID of the bribe.
    function getActivePeriodPerBribe(uint256 bribeId) public view returns (uint8) {
        Bribe storage bribe = bribes[bribeId];

        uint256 currentPeriod = getCurrentPeriod();
        uint256 periodsLeft = bribe.endTimestamp > currentPeriod ? (bribe.endTimestamp - currentPeriod) / _WEEK : 0;
        // If periodsLeft is superior, then the bribe didn't start yet.
        return uint8(periodsLeft > bribe.numberOfPeriods ? 0 : bribe.numberOfPeriods - periodsLeft);
    }

    /// @notice Return the current period based on Gauge Controller rounding.
    function getCurrentPeriod() public view returns (uint256) {
        return (block.timestamp / _WEEK) * _WEEK;
    }

    /// @notice Return the bias of a given address based on its lock end date and the current period.
    /// @param userSlope User slope.
    /// @param endLockTime Lock end date of the address.
    /// @param currentPeriod Current period.
    function _getAddrBias(uint256 userSlope, uint256 endLockTime, uint256 currentPeriod)
        internal
        pure
        returns (uint256)
    {
        if (currentPeriod + _WEEK >= endLockTime) return 0;
        return userSlope * (endLockTime - currentPeriod);
    }
}