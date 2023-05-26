// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./oz/interfaces/IERC20.sol";
import "./oz/libraries/SafeERC20.sol";
import "./oz/utils/ReentrancyGuard.sol";
import "./oz/utils/Pausable.sol";
import "./interfaces/IGaugeController.sol";
import "./utils/Owner.sol";

/** @title Warden Covenant */
/// @author Paladin
/*
    Contract to create custom deals for veToken votes on Gauge Controller
*/
contract Covenant is Owner, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // Storage

    /** @notice Seconds in a Week */
    uint256 private constant WEEK = 604800;
    /** @notice 1e18 scale */
    uint256 private constant UNIT = 1e18;
    /** @notice Max BPS */
    uint256 private constant MAX_BPS = 10000;

    /** @notice Address of the Curve Gauge Controller */
    address public immutable GAUGE_CONTROLLER;

    address public chest;
    uint256 public feeRatio = 200;

    mapping(address => bool) public allowedCreators;

    uint256 public nextID;
    mapping(uint256 => CovenantParams) public covenants;
    // ID => period => bias
    mapping(uint256 => mapping(uint256 => uint256)) public sumBiases;
    // ID => period => amount
    mapping(uint256 => mapping(uint256 => uint256)) public distributedAmount;
    // ID => period => amount
    mapping(uint256 => mapping(uint256 => uint256)) public claimedAmount;
    // ID => period => bool
    mapping(uint256 => mapping(uint256 => bool)) public distributed;
    // ID => period => bool
    mapping(uint256 => mapping(uint256 => bool)) public clawbacked;
    // ID => amount
    mapping(uint256 => uint256) public withdrawableAmount;
    // ID => listed voters
    mapping(uint256 => address[]) public allowedVoters;
    // voter => ID => bool
    mapping(address => mapping(uint256 => bool)) public isAllowedVoter;

    // voter => token => amount
    mapping(address => mapping(address => uint256)) public accruedAmount;
    // voter => ID -> period => bool
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public accrued;


    // Structs

    struct CovenantParams {
        address gauge;
        address token;
        uint256 targetBias;
        uint256 rewardPerVote;
        address creator;
        uint48 duration;
        uint48 firstPeriod;
    }


    // Events

    event CovenantCreated(uint256 id, address indexed creator, address indexed gauge);

    event UpdatedRewards(uint256 indexed id, uint256 indexed period);
    event WithdrewRewards(uint256 indexed id, uint256 amount);
    event ClawedBackRewards(uint256 indexed id, uint256 period, uint256 amount);

    event Accrued(uint256 indexed id, address indexed voter, uint256 indexed period);
    event Claimed(uint256 indexed id, address indexed voter, uint256 amount);

    event AddedVoter(uint256 indexed id, address indexed voter);
    event RemovedVoter(uint256 indexed id, address indexed voter);

    event SetCreator(address indexed creator, bool allowed);

    event ChestUpdated(address oldChest, address newChest);
    event FeeRatioUpdated(uint256 oldRatio, uint256 newRatio);


    // Errors

    error NotAllowed();
    error AlreadyListed();
    error NotListed();
    error InvalidPeriod();
    error InvalidGauge();
    error IncorrectDuration();
    error NullAmount();
    error NumberExceed48Bits();
    error InvalidParameter();
    error EmptyList();


    // Constructor
    constructor(address _gaugeController, address _chest) {
        if(_gaugeController == address(0) || _chest == address(0)) revert AddressZero();

        GAUGE_CONTROLLER = _gaugeController;
        chest = _chest;
    }


    // View methods

    function getCurrentPeriodEndTimestamp() public view returns(uint256) {
        // timestamp of the end of current voting period
        return ((block.timestamp + WEEK) / WEEK) * WEEK;
    }

    function getVoterList(uint256 id) external view returns(address[] memory){
        return allowedVoters[id];
    }

    function getCovenantPeriods(uint256 id) external view returns(uint256[] memory){
        CovenantParams memory _covenant = covenants[id];
        uint256[] memory periods = new uint256[](_covenant.duration);
        for(uint256 i; i < _covenant.duration;){
            periods[i] = _covenant.firstPeriod + (i * WEEK);

            unchecked{ ++i; }
        }
        return periods;
    }   


    // State-changing methods

    function createCovenant(
        address gauge,
        address rewardToken,
        uint256 firstPeriod,
        uint256 duration,
        uint256 targetBias,
        uint256 totalRewardAmount,
        address[] calldata voters
    ) external nonReentrant whenNotPaused returns(uint256 id) {
        // Check all parameters
        if(!allowedCreators[msg.sender]) revert NotAllowed();
        if(gauge == address(0) || rewardToken == address(0)) revert AddressZero();
        if(IGaugeController(GAUGE_CONTROLLER).gauge_types(gauge) < 0) revert InvalidGauge();
        if(duration == 0) revert IncorrectDuration();
        if(totalRewardAmount == 0 || targetBias == 0 || firstPeriod == 0) revert NullAmount();
        if(voters.length == 0) revert EmptyList();

        firstPeriod = (firstPeriod / WEEK) * WEEK;
        if(firstPeriod < block.timestamp) revert InvalidPeriod();

        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), totalRewardAmount);

        uint256 feeAmount = (totalRewardAmount * feeRatio) / MAX_BPS;
        totalRewardAmount -= feeAmount;

        IERC20(rewardToken).safeTransfer(chest, feeAmount);

        uint256 rewardPerPeriod = totalRewardAmount / duration;
        uint256 rewardPerVote = (rewardPerPeriod * UNIT) / targetBias;

        id = nextID;
        nextID++;

        covenants[id] = CovenantParams({
            gauge: gauge,
            token: rewardToken,
            targetBias: targetBias,
            rewardPerVote: rewardPerVote,
            creator: msg.sender,
            duration: uint48(duration),
            firstPeriod: uint48(firstPeriod)
        });

        _setVoters(id, voters);

        emit CovenantCreated(id, msg.sender, gauge);
    }

    function updatePeriodRewards(uint256 id, uint256 period) external nonReentrant whenNotPaused {
        _updatePeriodRewards(id, period);
    }

    function updateAllPeriodRewards(uint256 id) external nonReentrant whenNotPaused {
        CovenantParams memory _covenant = covenants[id];
        uint256 lastPeriod = _covenant.firstPeriod + ((_covenant.duration - 1) * WEEK);
        uint256 currentPeriod = getCurrentPeriodEndTimestamp();
        uint256 endUpdatePeriod = lastPeriod < currentPeriod ? lastPeriod : currentPeriod;
        
        uint256 periodIterator = _covenant.firstPeriod;

        while(periodIterator <= endUpdatePeriod){
            _updatePeriodRewards(id, periodIterator);
            periodIterator += WEEK;
        }
    }

    function withdrawUndistributed(uint256 id) external nonReentrant whenNotPaused {
        CovenantParams memory _covenant = covenants[id];
        if(_covenant.creator != msg.sender) revert NotAllowed();

        uint256 lastPeriod = _covenant.firstPeriod + ((_covenant.duration - 1) * WEEK);
        uint256 periodIterator = _covenant.firstPeriod;

        while(periodIterator <= lastPeriod){
            _clawbackRewards(id, periodIterator);
            periodIterator += WEEK;
        }

        uint256 amount = withdrawableAmount[id];
        withdrawableAmount[id] = 0;

        if(amount > 0) {
            IERC20(_covenant.token).safeTransfer(_covenant.creator, amount);
        }

        emit WithdrewRewards(id, amount);
    }

    function accrueVoterRewards(uint256 id, address voter) external nonReentrant whenNotPaused {
        if(!isAllowedVoter[voter][id]) revert NotListed();

        _accrueAllRewards(id, voter);
    }

    function claimRewards(uint256 id, address voter) external nonReentrant whenNotPaused returns(uint256 amount) {
        if(!isAllowedVoter[voter][id]) revert NotListed();

        _accrueAllRewards(id, voter);

        address token = covenants[id].token;

        amount = accruedAmount[voter][token];
        accruedAmount[voter][token] = 0;

        if(amount > 0) {
            IERC20(covenants[id].token).safeTransfer(voter, amount);
        }

        emit Claimed(id, voter, amount);
    }

    function addVoter(uint256 id, address voter) external nonReentrant whenNotPaused {
        if(voter == address(0)) revert AddressZero();
        if(covenants[id].creator != msg.sender) revert NotAllowed();
        if(isAllowedVoter[voter][id]) revert AlreadyListed();

        allowedVoters[id].push(voter);
        isAllowedVoter[voter][id] = true;

        emit AddedVoter(id, voter);
    }

    function removeVoter(uint256 id, address voter) external nonReentrant whenNotPaused {
        if(voter == address(0)) revert AddressZero();
        if(covenants[id].creator != msg.sender) revert NotAllowed();
        if(!isAllowedVoter[voter][id]) revert NotListed();

        address[] memory _list = allowedVoters[id];
        uint256 length = _list.length;
        if(length == 1) revert EmptyList();

        isAllowedVoter[voter][id] = false;

        for(uint256 i; i < length;){
            if(_list[i] == voter){
                if(i != length - 1){
                    allowedVoters[id][i] = _list[length - 1];
                }
                allowedVoters[id].pop();

                emit RemovedVoter(id, voter);

                return;
            }
            unchecked { ++i; }
        }
    }


    // Internal methods

    // Sum of all the voter biases
    function _getGaugeSumBias(uint256 id, address gauge, uint256 period) internal view returns(uint256 gaugeBias) {
        address[] memory _list = allowedVoters[id];
        uint256 length = _list.length;

        for(uint256 i; i < length;){
            (uint256 userBias,) = _getVoterBias(gauge, _list[i], period);

            gaugeBias += userBias;

            unchecked { ++i; }
        }
    }

    function _getVoterBias(
        address gauge,
        address voter,
        uint256 period
    ) internal view returns(uint256 userBias, uint256 lastUserVote) {
        IGaugeController gaugeController = IGaugeController(GAUGE_CONTROLLER);
        lastUserVote = gaugeController.last_user_vote(voter, gauge);
        IGaugeController.VotedSlope memory voteUserSlope = gaugeController.vote_user_slopes(voter, gauge);

        if(lastUserVote >= period) return (0,0);
        if(voteUserSlope.end <= period) return (0,0);
        if(voteUserSlope.slope == 0) return (0,0);

        userBias = voteUserSlope.slope * (voteUserSlope.end - period);
    }

    function _setVoters(uint256 id, address[] calldata voters) internal {
        uint256 length = voters.length;
        for(uint256 i = 0; i < length; i++) {
            if(isAllowedVoter[voters[i]][id]) revert AlreadyListed();

            allowedVoters[id].push(voters[i]);
            isAllowedVoter[voters[i]][id] = true;

            emit AddedVoter(id, voters[i]);
        }
    }

    function _updatePeriodRewards(uint256 id, uint256 period) internal {
        CovenantParams memory _covenant = covenants[id];
        uint256 lastPeriod = _covenant.firstPeriod + ((_covenant.duration - 1) * WEEK);
        if(period < _covenant.firstPeriod || period > lastPeriod) revert InvalidPeriod();
        if(distributed[id][period]) return;
        // We don't want to update rewards if the period is not over yet
        if(block.timestamp < period) return;

        IGaugeController(GAUGE_CONTROLLER).checkpoint_gauge(_covenant.gauge);

        uint256 periodSumBias = _getGaugeSumBias(id, _covenant.gauge, period);
        uint256 maxRewards = (_covenant.rewardPerVote * _covenant.targetBias) / UNIT;

        distributed[id][period] = true;

        if(periodSumBias >= _covenant.targetBias){
            distributedAmount[id][period] = maxRewards;
            sumBiases[id][period] = periodSumBias;
        } else {
            sumBiases[id][period] = periodSumBias;

            uint256 distributeAmount = (_covenant.rewardPerVote * periodSumBias) / UNIT;
            distributedAmount[id][period] = distributeAmount;
            withdrawableAmount[id] += maxRewards - distributeAmount;
        }

        emit UpdatedRewards(id, period);
    }

    function _accrueRewards(uint256 id, address voter, uint256 period) internal {
        if(accrued[voter][id][period]) return;
        // Do not accrue on non-distributed periods
        if(!distributed[id][period]) return;
        // Already clawbacked
        if(clawbacked[id][period]) return;

        uint256 gaugeSumBias = sumBiases[id][period];
        (uint256 voterBias, uint256 lastUserVote) = _getVoterBias(covenants[id].gauge, voter, period);

        accrued[voter][id][period] = true;

        if(gaugeSumBias != 0 && voterBias != 0 && lastUserVote < period) {
            // Get the share of the distributed rewards for this voter
            uint256 reward = (voterBias * distributedAmount[id][period]) / gaugeSumBias;
            accruedAmount[voter][covenants[id].token] += reward;

            claimedAmount[id][period] += reward;

            emit Accrued(id, voter, period);
        }
    }

    function _accrueAllRewards(uint256 id, address voter) internal {
        CovenantParams memory _covenant = covenants[id];
        uint256 lastPeriod = _covenant.firstPeriod + ((_covenant.duration - 1) * WEEK);
        uint256 periodIterator = _covenant.firstPeriod;

        while(periodIterator <= lastPeriod){
            _accrueRewards(id, voter, periodIterator);
            periodIterator += WEEK;
        }
    }

    function _clawbackRewards(uint256 id, uint256 period) internal {
        // Do not clawback on non-distributed periods
        if(!distributed[id][period]) return;
        // Do not clawback during the allowed distribution period
        if(block.timestamp <= period + WEEK) return;
        // Already clawbacked
        if(clawbacked[id][period]) return;

        clawbacked[id][period] = true;

        uint256 unclaimed = distributedAmount[id][period] - claimedAmount[id][period];
        withdrawableAmount[id] += unclaimed;

        emit ClawedBackRewards(id, period, unclaimed);
    }


    // Admin methods

    function setCreator(address creator, bool allowed) external onlyOwner {
        if(creator == address(0)) revert AddressZero();
        
        allowedCreators[creator] = allowed;

        emit SetCreator(creator, allowed);
    }

    function updateChest(address newChest) external onlyOwner {
        if(newChest == address(0)) revert AddressZero();
        address oldChest = chest;
        chest = newChest;

        emit ChestUpdated(oldChest, newChest);
    }

    function updateFeeRatio(uint256 newRatio) external onlyOwner {
        if(newRatio > 500) revert InvalidParameter();
        uint256 oldRatio = feeRatio;
        feeRatio = newRatio;

        emit FeeRatioUpdated(oldRatio, newRatio);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    // Maths

    function safe48(uint n) internal pure returns (uint48) {
        if(n > type(uint48).max) revert NumberExceed48Bits();
        return uint48(n);
    }

}