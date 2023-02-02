// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ShareWrapper.sol";
import "../utils/ContractGuard.sol";
import "../interfaces/ITreasury.sol";
import "../owner/Operator.sol";

contract SynergyARK is ShareWrapper, ContractGuard, Operator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== DATA STRUCTURES ========== */

    struct Memberseat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        uint256 epochTimerStart;
    }

    struct ARKSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    /* ========== STATE VARIABLES ========== */

    // flags
    bool public initialized = false;

    IERC20 public crystal;
    ITreasury public treasury;

    mapping(address => Memberseat) public members;
    ARKSnapshot[] public arkHistory;

    uint256 public withdrawLockupEpochs;
    uint256 public rewardLockupEpochs;

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);

    /* ========== Modifiers =============== */

    modifier memberExists() {
        require(balanceOf(msg.sender) > 0, "ARK: The member does not exist");
        _;
    }

    modifier updateReward(address _member) {
        if (_member != address(0)) {
            Memberseat memory seat = members[_member];
            seat.rewardEarned = earned(_member);
            seat.lastSnapshotIndex = latestSnapshotIndex();
            members[_member] = seat;
        }
        _;
    }

    modifier notInitialized() {
        require(!initialized, "ARK: already initialized");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        IERC20 _crystal,
        IERC20 _diamond,
        ITreasury _treasury
    ) public notInitialized {
        crystal = _crystal;
        diamond = _diamond;
        treasury = _treasury;

        ARKSnapshot memory genesisSnapshot = ARKSnapshot({time: block.number, rewardReceived: 0, rewardPerShare: 0});
        arkHistory.push(genesisSnapshot);

        withdrawLockupEpochs = 4; // Lock for 4 epochs (32h) before release withdraw
        rewardLockupEpochs = 3; // Lock for 3 epochs (24h) before release claimReward

        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        require(_withdrawLockupEpochs >= _rewardLockupEpochs && _withdrawLockupEpochs <= 56, "_withdrawLockupEpochs: out of range"); // <= 2 week
        withdrawLockupEpochs = _withdrawLockupEpochs;
        rewardLockupEpochs = _rewardLockupEpochs;
    }

    /* ========== VIEW FUNCTIONS ========== */

    // =========== Snapshot getters

    function latestSnapshotIndex() public view returns (uint256) {
        return arkHistory.length.sub(1);
    }

    function getLatestSnapshot() internal view returns (ARKSnapshot memory) {
        return arkHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address _member) public view returns (uint256) {
        return members[_member].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address _member) internal view returns (ARKSnapshot memory) {
        return arkHistory[getLastSnapshotIndexOf(_member)];
    }

    function canWithdraw(address _member) external view returns (bool) {
        return members[_member].epochTimerStart.add(withdrawLockupEpochs) <= treasury.epoch();
    }

    function canClaimReward(address _member) external view returns (bool) {
        return members[_member].epochTimerStart.add(rewardLockupEpochs) <= treasury.epoch();
    }

    function epoch() external view returns (uint256) {
        return treasury.epoch();
    }

    function nextEpochPoint() external view returns (uint256) {
        return treasury.nextEpochPoint();
    }

    function getCRSPrice() external view returns (uint256) {
        return treasury.getCRSPrice();
    }

    // =========== Member getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address _member) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(_member).rewardPerShare;

        return balanceOf(_member).mul(latestRPS.sub(storedRPS)).div(1e18).add(members[_member].rewardEarned);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 _amount) public override onlyOneBlock updateReward(msg.sender) {
        require(_amount > 0, "ARK: Stake amount should be bigger than 0");
        super.stake(_amount);
        members[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public override onlyOneBlock memberExists updateReward(msg.sender) {
        require(_amount > 0, "ARK: Withdraw amount should be bigger than 0");
        require(members[msg.sender].epochTimerStart.add(withdrawLockupEpochs) <= treasury.epoch(), "ARK: Withdraw is still locked");
        claimReward();
        super.withdraw(_amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function claimReward() public updateReward(msg.sender) {
        uint256 reward = members[msg.sender].rewardEarned;
        if (reward > 0) {
            require(members[msg.sender].epochTimerStart.add(rewardLockupEpochs) <= treasury.epoch(), "ARK: still in reward lockup");
            members[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
            members[msg.sender].rewardEarned = 0;
            crystal.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function allocateSeigniorage(uint256 _amount) external onlyOneBlock onlyOperator {
        require(_amount > 0, "ARK: Allocate amount should be bigger than 0");
        require(totalSupply() > 0, "ARK: Cannot allocate when totalSupply is 0");

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = prevRPS.add(_amount.mul(1e18).div(totalSupply()));

        ARKSnapshot memory newSnapshot = ARKSnapshot({time: block.number, rewardReceived: _amount, rewardPerShare: nextRPS});
        arkHistory.push(newSnapshot);

        crystal.safeTransferFrom(msg.sender, address(this), _amount);
        emit RewardAdded(msg.sender, _amount);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(crystal), "ARK: Shouldn't drain $CRS from ARK");
        require(address(_token) != address(diamond), "ARK: Shouldn't drain $DIA from ARK");
        _token.safeTransfer(_to, _amount);
    }
}