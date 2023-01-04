// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/Ive.sol";
import "../interfaces/IveListener.sol";
import "../interfaces/IveShareRoom.sol";

contract veShareRoom is IveShareRoom, IveListener, IERC721Receiver, ReentrancyGuard, PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    /* ========== DATA STRUCTURES ========== */

    struct Memberseat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        uint256 epochTimerStart;
    }

    struct BoardroomSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    /* ========== STATE VARIABLES ========== */

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _depositedNFT;
    mapping(uint256 => address) private _stakerOfNFT;

    // epoch
    uint256 public startTime;
    uint256 public lastEpochTime;
    uint256 private epoch_ = 0;
    uint256 private epochLength_ = 0;

    // reward
    uint256 public totalStakeBalance; // ~BCXS
    uint256 public epochReward; // CAKE
    uint256 public epochRewardBase;

    address public ve;
    address public reward; // CAKE

    address public reserveFund;

    address public voter;

    mapping(address => Memberseat) public members;
    BoardroomSnapshot[] public boardroomHistory;

    uint256 public withdrawLockupEpochs;
    uint256 public totalDistributedReward; // CAKE

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 tokenId, uint256 weight);
    event Withdrawn(address indexed user, uint256 tokenId, uint256 weight);
    event EmergencyWithdraw(address indexed user, uint256 tokenId, uint256 weight);
    event RewardPaid(address indexed user, uint256 earned);
    event RewardTaxed(address indexed user, uint256 taxed);
    event RewardAdded(address indexed user, uint256 amount);
    event AllocateReward(uint256 amount);
    event OnERC721Received(address operator, address from, uint256 tokenId, bytes data);

    /* ========== Modifiers =============== */

    modifier checkEpoch() {
        uint256 _nextEpochPoint = nextEpochPoint();
        require(block.timestamp >= _nextEpochPoint, "!opened");

        _;

        lastEpochTime = _nextEpochPoint;
        epoch_ += 1;
    }

    modifier onlyVoter() {
        require(msg.sender == voter, "!voter");
        _;
    }

    modifier memberExists() {
        require(_balances[msg.sender] > 0, "The member does not exist");
        _;
    }

    modifier updateReward(address member) {
        if (member != address(0)) {
            _updateReward(member);
        }
        _;
    }

    function _updateReward(address member) internal {
        Memberseat memory seat = members[member];
        seat.rewardEarned = earned(member);
        seat.lastSnapshotIndex = latestSnapshotIndex();
        members[member] = seat;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _reward,
        address _ve,
        address _reserveFund,
        uint256 _startTime
    ) external initializer {
        PausableUpgradeable.__Pausable_init();
        OwnableUpgradeable.__Ownable_init();

        reward = _reward;
        ve = _ve;
        reserveFund = _reserveFund; // Dao Fund (to receive tax)

        BoardroomSnapshot memory genesisSnapshot = BoardroomSnapshot({time: block.number, rewardReceived: 0, rewardPerShare: 0});
        boardroomHistory.push(genesisSnapshot);

        startTime = _startTime;
        epochLength_ = 14 days;
        lastEpochTime = _startTime - 14 days;

        withdrawLockupEpochs = 1; // Lock for 1 epochs

        epochReward = epochRewardBase = 10 ether; // 10 CAKE
    }

    function setNextEpochPoint(uint256 _nextEpochPoint) external onlyOwner {
        require(_nextEpochPoint >= block.timestamp, "nextEpochPoint could not be the past");
        lastEpochTime = _nextEpochPoint - epochLength_;
    }

    function setNewVoter(address _newVoter) external onlyOwner {
        require(_newVoter != address(0), "zero");
        voter = _newVoter;
    }

    function setEpochLength(uint256 _epochLength) external onlyOwner {
        require(_epochLength >= 1 days && _epochLength <= 56 days, "out of range");
        epochLength_ = _epochLength;
    }

    function setLockUp(uint256 _withdrawLockupEpochs) external onlyOwner {
        require(_withdrawLockupEpochs <= 56, "out of range"); // <= 2 week
        withdrawLockupEpochs = _withdrawLockupEpochs;
    }

    function setEpochReward(uint256 _epochReward) external onlyOwner {
        epochReward = _epochReward;
    }

    function setEpochRewardBase(uint256 _epochRewardBase) external onlyOwner {
        epochRewardBase = _epochRewardBase;
    }

    function setReserveFund(address _reserveFund) external onlyOwner {
        require(_reserveFund != address(0), "zero");
        reserveFund = _reserveFund;
    }

    function setNewVe(address _newVe) external onlyOwner {
        require(_newVe != address(0), "zero");
        ve = _newVe;
    }

    function setNewReward(address _newReward) external onlyOwner {
        IERC20 _oldReward = IERC20(reward);
        _oldReward.safeTransfer(owner(), _oldReward.balanceOf(address(this)));
        reward = _newReward;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function depositedNFT(address account) external view returns (uint256) {
        return _depositedNFT[account];
    }

    function stakerOfNFT(uint256 tokenId) external override view returns (address) {
        return _stakerOfNFT[tokenId];
    }

    function epoch() public view returns (uint256) {
        return epoch_;
    }

    function nextEpochPoint() public view returns (uint256) {
        return lastEpochTime + nextEpochLength();
    }

    function nextEpochLength() public view returns (uint256) {
        return epochLength_;
    }

    // =========== Snapshot getters

    function latestSnapshotIndex() public view returns (uint256) {
        return boardroomHistory.length - 1;
    }

    function getLatestSnapshot() internal view returns (BoardroomSnapshot memory) {
        return boardroomHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address member) public view returns (uint256) {
        return members[member].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address member) internal view returns (BoardroomSnapshot memory) {
        return boardroomHistory[getLastSnapshotIndexOf(member)];
    }

    function canWithdraw(address member) external view returns (bool) {
        return members[member].epochTimerStart + withdrawLockupEpochs <= epoch_;
    }

    // =========== Member getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address member) public view returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(member).rewardPerShare;

        return _balances[member] * (latestRPS - storedRPS) / 1e18 + members[member].rewardEarned;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _stake(uint256 _tokenId) internal virtual {
        uint256 _weight = uint256(Ive(ve).balanceOfNFT(_tokenId));
        _totalSupply += _weight;
        _balances[msg.sender] = _weight;
        _depositedNFT[msg.sender] = _tokenId;
        _stakerOfNFT[_tokenId] = msg.sender;
        IERC721(ve).safeTransferFrom(msg.sender, address(this), _tokenId);
        emit Staked(msg.sender, _tokenId, _weight);
    }

    function _withdraw(uint256 _tokenId) internal virtual {
        uint256 _weight = _balances[msg.sender];
        _totalSupply -= _weight;
        _balances[msg.sender] = 0;
        _depositedNFT[msg.sender] = 0;
        _stakerOfNFT[_tokenId] = address(0);
        IERC721(ve).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit Withdrawn(msg.sender, _tokenId, _weight);
    }

    function stake(uint256 _tokenId) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(Ive(ve).isApprovedOrOwner(msg.sender, _tokenId), "!owned");
        require(_depositedNFT[msg.sender] == 0, "unstake first");
        if (members[msg.sender].rewardEarned > 0) {
            claimReward();
        }
        _stake(_tokenId);
        members[msg.sender].epochTimerStart = epoch_; // reset timer
    }

    function exit() external nonReentrant memberExists whenNotPaused updateReward(msg.sender) {
        uint256 _tokenId = _depositedNFT[msg.sender];
        require(_tokenId > 0, "!staked");
        require(members[msg.sender].epochTimerStart + withdrawLockupEpochs <= epoch_, "still in withdraw lockup");
        _taxReward();
        _withdraw(_tokenId);
    }

    function emergencyWithdraw() external nonReentrant memberExists whenNotPaused updateReward(msg.sender) {
        uint256 _tokenId = _depositedNFT[msg.sender];
        require(_tokenId > 0, "!staked");
        _taxReward();
        Ive _ve = Ive(ve);
        IERC20 _token = IERC20(_ve.token());
        uint256 _before = _token.balanceOf(address(this));
        _ve.emergencyWithdraw(_tokenId);
        uint256 _weight = _token.balanceOf(address(this)) - _before; // _weight is original weight subtracted fee for early withdraw
        _totalSupply -= _balances[msg.sender];
        _balances[msg.sender] = 0;
        _depositedNFT[msg.sender] = 0;
        _stakerOfNFT[_tokenId] = address(0);
        _token.safeTransfer(msg.sender, _weight);
        emit EmergencyWithdraw(msg.sender, _tokenId, _weight);
    }

    function _taxReward() internal updateReward(msg.sender) {
        uint256 _earned = members[msg.sender].rewardEarned;
        if (_earned > 0) {
            members[msg.sender].rewardEarned = 0;
            _safeRewardTransfer(reserveFund, _earned);
            emit RewardTaxed(msg.sender, _earned);
        }
    }

    function claimReward() public updateReward(msg.sender) {
        uint256 _earned = members[msg.sender].rewardEarned;
        if (_earned > 0) {
            members[msg.sender].epochTimerStart = epoch_; // reset timer
            members[msg.sender].rewardEarned = 0;
            _safeRewardTransfer(msg.sender, _earned);
            emit RewardPaid(msg.sender, _earned);
        }
    }

    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        IERC20 _reward = IERC20(reward);
        uint256 _rewardBal = _reward.balanceOf(address(this));
        if (_rewardBal > 0) {
            if (_amount > _rewardBal) {
                _reward.safeTransfer(_to, _rewardBal);
            } else {
                _reward.safeTransfer(_to, _amount);
            }
        }
    }

    function onTokenWeightUpdated(uint256 _tokenId) external override {
        address _staker = _stakerOfNFT[_tokenId];
        if (_staker != address(0)) {
            _updateReward(_staker);
            uint256 _weight = _balances[_staker];
            _totalSupply -= _weight;
            _weight = uint256(Ive(ve).balanceOfNFT(_tokenId));
            _totalSupply += _weight;
            _balances[_staker] = _weight;
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        emit OnERC721Received(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    function nft_increase_amount(uint256 _tokenId, uint _value) external {
        Ive _ve = Ive(ve);
        IERC20 _token = IERC20(_ve.token());
        _token.safeTransferFrom(msg.sender, address(this), _value);
        _token.safeIncreaseAllowance(address(_ve), _value);
        _ve.increase_amount(_tokenId, _value);
    }

    function nft_increase_unlock_time(uint _lock_duration) external {
        uint256 _tokenId = _depositedNFT[msg.sender];
        require(_tokenId > 0, "!staked");
        Ive(ve).increase_unlock_time(_tokenId, _lock_duration);
    }

    function allocateReward() public nonReentrant whenNotPaused {
        _allocateReward();
    }

    function _allocateReward() internal checkEpoch {
        uint256 _amount = epochReward;
        require(_amount > 0, "Cannot allocate 0");
        require(_totalSupply > 0, "Cannot allocate when totalSupply is 0");

        // Create & add new snapshot
        uint256 prevRPS = getLatestSnapshot().rewardPerShare;
        uint256 nextRPS = prevRPS + (_amount * 1e18 / _totalSupply);

        BoardroomSnapshot memory newSnapshot = BoardroomSnapshot({time: block.number, rewardReceived: _amount, rewardPerShare: nextRPS});
        boardroomHistory.push(newSnapshot);

        totalDistributedReward += _amount;
        epochReward = epochRewardBase; // reset reward back to 10 CAKE for new epoch
        emit AllocateReward(_amount);
    }

    function topupEpochReward(uint256 _amount) external nonReentrant whenNotPaused {
        if (_amount > 0) {
            epochReward += _amount;

            IERC20(reward).safeTransferFrom(msg.sender, address(this), _amount);
            emit RewardAdded(msg.sender, _amount);
        }

        if (block.timestamp >= nextEpochPoint()) {
            _allocateReward();
        }
    }

    /* ========== EMERGENCY ========== */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function rescueStuckErc20(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}