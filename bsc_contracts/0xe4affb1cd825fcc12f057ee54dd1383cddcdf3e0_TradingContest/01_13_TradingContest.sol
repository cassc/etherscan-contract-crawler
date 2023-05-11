// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ILVLStaking} from "src/interfaces/ILVLStaking.sol";
import {IDaoStaking} from "src/interfaces/contest/IDaoStaking.sol";
import {LeaderInfo, ContestResult, LeaderInfoView, BatchInfo} from "src/interfaces/contest/ITradingContest.sol";

contract TradingContest is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /*================= VARIABLES ================*/
    using SafeERC20 for IERC20;

    uint64 public constant MAX_BATCH_DURATION = 30 days;
    uint64 public constant MAX_VESTING_DURATION = 7 days;
    uint128 public constant TOKEN_PRECISION = 1e18;
    uint128 public constant BONUS_PRECISION = 1e10;
    uint128 public constant BONUS_PER_TOKEN = 1e5;

    uint128 public constant TOTAL_WEIGHT = 35200;

    uint64 public currentBatch;
    uint64 public vestingDuration;
    uint64 public batchDuration;

    address public poolHook;
    address public updater;
    address public admin;
    address public controller;

    bool public enableNextBatch;

    ILVLStaking public lvlStaking;
    IDaoStaking public daoStaking;
    IERC20 public LVL;

    mapping(uint64 => BatchInfo) public batches;
    mapping(uint64 => mapping(address => LeaderInfo)) public leaders;
    mapping(uint64 => address[]) private leaderAddresses;

    // rank => weight
    mapping(uint8 => uint64) public rewardWeights;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _poolHook, address _lvl, address _lvlStaking, address _daoStaking)
        external
        initializer
    {
        require(_poolHook != address(0), "Invalid address");
        require(_lvl != address(0), "Invalid address");
        require(_lvlStaking != address(0), "Invalid address");
        require(_daoStaking != address(0), "Invalid address");
        __Ownable_init();
        __ReentrancyGuard_init();
        poolHook = _poolHook;
        LVL = IERC20(_lvl);
        lvlStaking = ILVLStaking(_lvlStaking);
        daoStaking = IDaoStaking(_daoStaking);

        vestingDuration = 1 days;
        batchDuration = 1 days;

        rewardWeights[0] = 10000;
        rewardWeights[1] = 6000;
        rewardWeights[2] = 4000;
        rewardWeights[3] = 3000;
        rewardWeights[4] = 2500;
        rewardWeights[5] = 2000;
        rewardWeights[6] = 1700;
        rewardWeights[7] = 1400;
        rewardWeights[8] = 1100;
        rewardWeights[9] = 800;
        rewardWeights[10] = 600;
        rewardWeights[11] = 500;
        rewardWeights[12] = 400;
        rewardWeights[13] = 300;
        rewardWeights[14] = 200;
        rewardWeights[15] = 180;
        rewardWeights[16] = 160;
        rewardWeights[17] = 140;
        rewardWeights[18] = 120;
        rewardWeights[19] = 100;
    }
    /*================= VIEWS ======================*/

    function getNextBatch() public view returns (uint64 _nextBatchTimestamp, uint64 _vestingDuration) {
        _nextBatchTimestamp = batches[currentBatch].startTime + batchDuration;
        _vestingDuration = vestingDuration;
    }

    function getLeaders(uint64 _batchId) public view returns (LeaderInfoView[] memory _leaders) {
        address[] memory _addresses = leaderAddresses[_batchId];
        if (_addresses.length > 0) {
            _leaders = new LeaderInfoView[](_addresses.length);
            BatchInfo memory _batchInfo = batches[_batchId];
            uint128 _totalWeight = _batchInfo.totalWeight == 0 ? TOTAL_WEIGHT : _batchInfo.totalWeight;
            for (uint256 index = 0; index < _addresses.length; index++) {
                address _addr = _addresses[index];
                LeaderInfo memory _info = leaders[_batchId][_addr];
                _leaders[index] = LeaderInfoView({
                    trader: _addr,
                    index: _info.index,
                    totalPoint: _info.totalPoint,
                    rewardTokens: uint128(uint256(_batchInfo.rewardTokens) * uint256(_info.weight) / _totalWeight),
                    claimed: _info.claimed
                });
            }
        }
    }

    function getClaimableRewards(uint64 _batchId, address _user) public view returns (uint256 _claimableRewards) {
        BatchInfo memory _batchInfo = batches[_batchId];
        if (_batchInfo.startVestingTime > 0) {
            LeaderInfo memory _leader = leaders[_batchId][_user];
            uint128 _totalWeight = _batchInfo.totalWeight == 0 ? TOTAL_WEIGHT : _batchInfo.totalWeight;
            if (_leader.weight > 0) {
                if (block.timestamp >= _batchInfo.startVestingTime + _batchInfo.vestingDuration) {
                    _claimableRewards =
                        uint256(_batchInfo.rewardTokens) * uint256(_leader.weight) / _totalWeight - _leader.claimed;
                } else {
                    uint256 _time = block.timestamp - _batchInfo.startVestingTime;
                    _claimableRewards = (
                        _time * uint256(_batchInfo.rewardTokens) * uint256(_leader.weight) / _totalWeight
                            / _batchInfo.vestingDuration
                    ) - _leader.claimed;
                }
            }
        }
    }

    /*=================== MULTITATIVE =====================*/

    function claimRewards(uint64 _batchId, address _to) external nonReentrant {
        uint256 _claimableRewards = getClaimableRewards(_batchId, msg.sender);
        if (_claimableRewards > 0) {
            leaders[_batchId][msg.sender].claimed += uint128(_claimableRewards);
            LVL.safeTransfer(_to, _claimableRewards);
            emit Claimed(msg.sender, _to, _batchId, _claimableRewards);
        }
    }

    function claimMultiple(uint64[] memory _batchIds, address _to) external nonReentrant {
        uint256 _totalClaimableRewards = 0;
        for (uint64 index = 0; index < _batchIds.length; index++) {
            uint64 _batchId = _batchIds[index];
            BatchInfo memory _batchInfo = batches[_batchId];

            if (_batchInfo.startVestingTime > 0) {
                uint256 _claimableRewards = getClaimableRewards(_batchId, msg.sender);
                if (_claimableRewards > 0) {
                    leaders[_batchId][msg.sender].claimed += uint128(_claimableRewards);
                    _totalClaimableRewards += _claimableRewards;
                    emit Claimed(msg.sender, _to, _batchId, _claimableRewards);
                }
            }
        }
        if (_totalClaimableRewards > 0) {
            LVL.safeTransfer(_to, _totalClaimableRewards);
        }
    }

    function record(address _user, uint256 _value) external {
        require(msg.sender == poolHook, "Only poolHook");
        if (
            currentBatch > 0 && block.timestamp >= batches[currentBatch].startTime && batches[currentBatch].endTime == 0
        ) {
            (uint256 _lvlAmount,) = lvlStaking.userInfo(_user);
            (uint256 _lvlDAOAmount,,) = daoStaking.userInfo(_user);
            uint256 _bonusRatio = (_lvlAmount + _lvlDAOAmount) * uint256(BONUS_PER_TOKEN) / TOKEN_PRECISION;

            uint256 _bonusPoint = _value * _bonusRatio / BONUS_PRECISION;
            uint256 _point = _value + _bonusPoint;
            emit RecordAdded(_user, _value, _lvlDAOAmount, _lvlAmount, _point, currentBatch);
        }
    }

    function addReward(uint256 _rewardTokens) external nonReentrant {
        require(msg.sender == controller, "!Controller");
        require(batches[currentBatch].startTime > 0, "Not exists");
        require(batches[currentBatch].startVestingTime == 0, "Finalized");
        LVL.safeTransferFrom(msg.sender, address(this), _rewardTokens);
        batches[currentBatch].rewardTokens += uint128(_rewardTokens);
        emit RewardAdded(currentBatch, _rewardTokens);
    }

    function increaseReward(uint64 _batchId, uint256 _rewardTokens) external nonReentrant {
        require(msg.sender == admin, "!admin");
        require(batches[_batchId].startTime > 0, "Not exists");
        require(batches[_batchId].startVestingTime == 0, "Finalized");
        LVL.safeTransferFrom(msg.sender, address(this), _rewardTokens);
        batches[_batchId].rewardTokens += uint128(_rewardTokens);
        emit RewardIncreased(_batchId, _rewardTokens);
    }

    function decreaseReward(uint64 _batchId, uint256 _amount) external nonReentrant {
        require(msg.sender == admin, "!admin");
        require(batches[_batchId].startTime > 0, "Not exists");
        require(batches[_batchId].startVestingTime == 0, "Finalized");
        batches[_batchId].rewardTokens -= uint128(_amount);
        emit RewardDecreased(_batchId, _amount);
    }

    function forceNextBatch() external {
        require(msg.sender == admin, "!Admin");
        require(enableNextBatch, "!enableNextBatch");
        require(currentBatch > 0, "Not start");
        (uint64 _nextBatchTimestamp,) = getNextBatch();
        require(block.timestamp >= _nextBatchTimestamp, "now < trigger time");
        _nextBatch(_nextBatchTimestamp);
    }

    function nextBatch() external {
        require(enableNextBatch, "!enableNextBatch");
        require(currentBatch > 0, "Not start");
        (uint64 _nextBatchTimestamp,) = getNextBatch();
        require(block.timestamp >= _nextBatchTimestamp, "now < trigger time");
        require(batches[currentBatch].rewardTokens > 0, "Reward = 0");
        _nextBatch(_nextBatchTimestamp);
    }

    function updateLeaders(uint64 _batchId, ContestResult[] memory _leaders) external {
        require(msg.sender == updater || msg.sender == admin, "Only updater or admin");
        BatchInfo memory _batchInfo = batches[_batchId];
        require(_batchInfo.endTime > 0, "!Ended");
        require(_batchInfo.startVestingTime == 0, "Finalized");
        require(_leaders.length <= 20, "Invalid leaders");

        address[] memory _leaderAddresses = leaderAddresses[_batchId];
        for (uint256 index = 0; index < _leaderAddresses.length; index++) {
            delete leaders[_batchId][_leaderAddresses[index]];
        }
        delete leaderAddresses[_batchId];

        for (uint256 index = 0; index < _leaders.length; index++) {
            ContestResult memory _leader = _leaders[index];
            leaders[_batchId][_leader.trader] = LeaderInfo({
                weight: rewardWeights[_leader.index - 1],
                index: _leader.index,
                totalPoint: _leader.totalPoint,
                claimed: 0
            });
            leaderAddresses[_batchId].push(_leader.trader);
        }
        _batchInfo.leaderUpdated = true;
        batches[_batchId] = _batchInfo;
        emit LeaderUpdated(_batchId);
    }

    function finalize(uint64 _batchId) external {
        require(msg.sender == admin, "!Admin");
        BatchInfo memory _batchInfo = batches[_batchId];
        require(_batchInfo.startVestingTime == 0, "Finalized");
        require(_batchInfo.leaderUpdated, "Leaders has not been updated yet");
        _batchInfo.startVestingTime = uint64(block.timestamp);
        _batchInfo.vestingDuration = vestingDuration;
        _batchInfo.totalWeight = TOTAL_WEIGHT;

        batches[_batchId] = _batchInfo;
        emit Finalized(_batchId);
    }

    /*================ ADMIN ===================*/
    function setPoolHook(address _poolHook) external onlyOwner {
        require(_poolHook != address(0), "Invalid address");
        poolHook = _poolHook;
        emit PoolHookSet(_poolHook);
    }

    function start(uint256 _startTime) external {
        require(_startTime >= block.timestamp, "start time < current time");
        require(currentBatch == 0, "Started");
        currentBatch = 1;
        batches[currentBatch].startTime = uint64(_startTime);
        emit BatchStarted(currentBatch);
    }

    function withdrawLVL(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid address");
        LVL.safeTransfer(_to, _amount);
        emit LVLWithdrawn(_to, _amount);
    }

    function setBatchDuration(uint64 _duration) external onlyOwner {
        require(_duration > 0, "Invalid batch duration");
        require(_duration <= MAX_BATCH_DURATION, "!MAX_BATCH_DURATION");
        batchDuration = _duration;
        emit BatchDurationSet(_duration);
    }

    function setVestingDuration(uint64 _duration) external onlyOwner {
        require(_duration <= MAX_VESTING_DURATION, "!MAX_VESTING_DURATION");
        vestingDuration = _duration;
        emit VestingDurationSet(_duration);
    }

    function setDaoStaking(address _daoStaking) external onlyOwner {
        require(_daoStaking != address(0), "Invalid address");
        daoStaking = IDaoStaking(_daoStaking);
        emit DaoStakingSet(_daoStaking);
    }

    function setLvlStaking(address _lvlStaking) external onlyOwner {
        require(_lvlStaking != address(0), "Invalid address");
        lvlStaking = ILVLStaking(_lvlStaking);
        emit LvlStakingSet(_lvlStaking);
    }

    function setEnableNextBatch(bool _enable) external {
        require(msg.sender == admin, "!Admin");
        enableNextBatch = _enable;
        emit EnableNextBatchSet(_enable);
    }

    function setUpdater(address _updater) external onlyOwner {
        require(_updater != address(0), "Invalid address");
        updater = _updater;
        emit UpdaterSet(_updater);
    }

    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Invalid address");
        admin = _admin;
        emit AdminSet(_admin);
    }

    function setController(address _controller) external onlyOwner {
        require(_controller != address(0), "Invalid address");
        controller = _controller;
        emit ControllerSet(_controller);
    }

    /*================ INTERNAL =============== */

    function _nextBatch(uint64 _nextBatchTimestamp) internal {
        batches[currentBatch].endTime = _nextBatchTimestamp;
        emit BatchEnded(currentBatch);

        currentBatch++;
        batches[currentBatch].startTime = _nextBatchTimestamp;
        emit BatchStarted(currentBatch);
    }

    /*================ EVENTS ===================*/
    event LvlStakingSet(address _lvlStaking);
    event DaoStakingSet(address _daoStaking);
    event BatchStarted(uint64 _currentBatch);
    event PoolHookSet(address _poolHook);
    event BatchDurationSet(uint64 _duration);
    event VestingDurationSet(uint64 _duration);
    event Finalized(uint64 _batchId);
    event RecordAdded(
        address _user, uint256 _value, uint256 _daoStaking, uint256 _lvlStaking, uint256 _point, uint64 _batchId
    );
    event EnableNextBatchSet(bool _enable);
    event Claimed(address _user, address _to, uint128 _batchId, uint256 _amount);
    event LVLWithdrawn(address _to, uint256 _amount);
    event LeaderUpdated(uint64 _batchId);
    event UpdaterSet(address _addr);
    event AdminSet(address _addr);
    event BatchEnded(uint64 _batchId);
    event RewardAdded(uint64 _batchId, uint256 _rewardTokens);
    event RewardIncreased(uint64 _batchId, uint256 _amount);
    event RewardDecreased(uint64 _batchId, uint256 _amount);
    event ControllerSet(address _controller);
}