// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IMultiMintNFT.sol";
import "./utils/TokenWithdraw.sol";

contract UndeadStaking is OwnableUpgradeable, ReentrancyGuardUpgradeable, TokenWithdraw, AccessControlUpgradeable {
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  struct UserInfo {
    address addr;
    uint256 amount;
    uint256 claimed;
    // Next deposit id, start from 0
    uint256 depositId;
    bool registered;
  }

  struct DepositInfo {
    uint256 id;
    uint256 amount;
    uint256 reward;
    uint256 lockedFrom;
    uint256 lockedTo;
    uint256 fixedAPY;
    uint256 lastRewardTime;
    uint256 depositTime;
  }

  struct LogRecord {
    address addr;
    uint256 amount1;
    uint256 amount2;
    bool isDeposit;
    uint256 logTime;
  }

  bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
  bytes32 private constant _EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

  uint256 private constant _RATE_NOMINATOR = 10000;
  uint256 public constant SECONDS_YEAR = 365 days;

  IERC20MetadataUpgradeable public rewardToken;
  IERC20MetadataUpgradeable public stakedToken;

  mapping(address => UserInfo) public userInfo;
  address[] public userList;
  mapping(address => mapping(uint256 => DepositInfo)) public depositInfos;
  LogRecord[] private _logRecords;

  uint256 public maxRewardPerPool;
  uint256 public claimedRewardPerPool;
  uint256 public currentStakedPerPool;
  uint256 public maxStakedPerPool;
  uint256 public poolRewardNeeded;

  uint256 public freezeStartTime;
  uint256 public freezeEndTime;

  uint256 public startTime;
  uint256 public endTime;
  uint256 public fixedAPY;
  uint256 public lockDuration;
  bool public limitRewardEnable;

  // NFT config
  address public nftToken;
  uint256 public nftPkgId;
  uint256 public nftTokenId;
  uint256 public nftStakedRequired;
  mapping(address => uint256) public nftStakedProgress;
  mapping(address => uint256) public nftMintedCounter;

  event EDeposit(address indexed user, uint256 depositId, uint256 amount);
  event EWithdraw(address indexed user, uint256 depositId, uint256 amount);
  event ENewStartAndEndTimes(uint256 startTime, uint256 endTime);
  event ENewFreezeTimes(uint256 freezeStartTime, uint256 freezeEndTime);
  event EMintNFT(address toAddr, uint256 from, uint256 to, uint256 pkgId);

  function __UndeadStaking_init(
    IERC20MetadataUpgradeable _stakedToken,
    IERC20MetadataUpgradeable _rewardToken,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _fixedAPY,
    uint256 _lockedDuration,
    address _nftToken,
    uint256 _nftPkgId,
    uint256 _nftTokenId,
    uint256 _nftStakedRequired
  ) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(EDITOR_ROLE, _msgSender());

    stakedToken = _stakedToken;
    rewardToken = _rewardToken;

    startTime = _startTime;
    endTime = _endTime;
    fixedAPY = _fixedAPY;
    lockDuration = _lockedDuration;

    nftToken = _nftToken;
    nftPkgId = _nftPkgId;
    nftTokenId = _nftTokenId;
    nftStakedRequired = _nftStakedRequired;
  }

  function getRemainingReward() public view returns (uint256) {
    if (maxRewardPerPool > claimedRewardPerPool) return maxRewardPerPool - claimedRewardPerPool;
    return 0;
  }

  function getPoolRewardNeededRemaining() external view returns (uint256) {
    return getRemainingReward() - poolRewardNeeded;
  }

  function estMaxReward(
    uint256 _amount,
    uint256 _fixedAPY,
    uint256 _lockTime
  ) public pure returns (uint256) {
    return (_amount * _fixedAPY * _lockTime) / SECONDS_YEAR / _RATE_NOMINATOR;
  }

  function estMaxStakedByReward(
    uint256 _rewardAmount,
    uint256 _fixedAPY,
    uint256 _lockTime
  ) external pure returns (uint256) {
    return (_rewardAmount * _RATE_NOMINATOR * SECONDS_YEAR) / (_fixedAPY * _lockTime);
  }

  function getPendingReward(address _user, uint256 _depositId) public view returns (uint256) {
    DepositInfo storage userDeposit = depositInfos[_user][_depositId];
    uint userReward;
    if (block.timestamp > userDeposit.lastRewardTime && currentStakedPerPool != 0) {
      uint256 multiplier = _getMultiplier(
        userDeposit.lastRewardTime,
        block.timestamp,
        userDeposit.lockedFrom,
        userDeposit.lockedTo
      );
      if (multiplier == 0) return 0;

      // Interest = Amount * APY * Duration / TotalSecondInYears
      userReward = estMaxReward(userDeposit.amount, userDeposit.fixedAPY, multiplier);
    }
    return userReward;
  }

  function getLogRecordLength() external view returns (uint) {
    return _logRecords.length;
  }

  function getLogRecordsPaging(uint _offset, uint _limit)
    external
    view
    returns (
      LogRecord[] memory users,
      uint nextOffset,
      uint total
    )
  {
    uint totalUsers = _logRecords.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers - _offset) {
      _limit = totalUsers - _offset;
    }

    LogRecord[] memory values = new LogRecord[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values[i] = _logRecords[_offset + i];
    }

    return (values, _offset + _limit, totalUsers);
  }

  function getUserListLength() external view returns (uint) {
    return userList.length;
  }

  function getUsersPaging(uint _offset, uint _limit)
    external
    view
    returns (
      UserInfo[] memory users,
      uint nextOffset,
      uint total
    )
  {
    uint totalUsers = userList.length;
    if (_limit == 0) {
      _limit = 1;
    }

    if (_limit > totalUsers - _offset) {
      _limit = totalUsers - _offset;
    }

    UserInfo[] memory values = new UserInfo[](_limit);
    for (uint i = 0; i < _limit; i++) {
      values[i] = userInfo[userList[_offset + i]];
    }

    return (values, _offset + _limit, totalUsers);
  }

  function isFrozen() public view returns (bool) {
    return block.timestamp >= freezeStartTime && block.timestamp <= freezeEndTime;
  }

  function emergencyRewardWithdraw(uint256 _amount) external onlyRole(_EMERGENCY_ROLE) {
    maxRewardPerPool -= _amount;
    rewardToken.safeTransfer(address(msg.sender), _amount);
  }

  function setLockDuration(uint256 _duration) external onlyRole(EDITOR_ROLE) {
    lockDuration = _duration;
  }

  function setDepositLock(
    address _user,
    uint256 _depositId,
    uint256 _lockTo
  ) external onlyRole(_EMERGENCY_ROLE) {
    DepositInfo storage userDeposit = depositInfos[_user][_depositId];
    require(userDeposit.amount > 0, "Empty");
    require(userDeposit.reward == 0, "Claimed");
    require(_lockTo > block.timestamp, "Invalid time");

    uint256 oldDuration = userDeposit.lockedTo - userDeposit.lockedFrom;
    poolRewardNeeded -= estMaxReward(userDeposit.amount, userDeposit.fixedAPY, oldDuration);

    userDeposit.lockedTo = _lockTo;
    uint256 newDuration = userDeposit.lockedTo - userDeposit.lockedFrom;
    poolRewardNeeded += estMaxReward(userDeposit.amount, userDeposit.fixedAPY, newDuration);

    require(getRemainingReward() >= poolRewardNeeded, "Insufficient rewards");
  }

  function addRewardTokens(uint256 _amount) external onlyRole(EDITOR_ROLE) {
    // Check real amount to avoid taxed token
    uint256 previousBalance_ = rewardToken.balanceOf(address(this));
    rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    uint256 newBalance_ = rewardToken.balanceOf(address(this));
    uint256 addedAmount_ = newBalance_ - previousBalance_;

    maxRewardPerPool += addedAmount_;
  }

  function stopReward() external onlyRole(EDITOR_ROLE) {
    endTime = block.timestamp;
  }

  function stopFreeze() external onlyRole(EDITOR_ROLE) {
    freezeStartTime = 0;
    freezeEndTime = 0;
  }

  function updateMaxStakedPerPool(uint256 _maxStakedPerPool) external onlyRole(EDITOR_ROLE) {
    maxStakedPerPool = _maxStakedPerPool;
  }

  function updateLimitRewardEnable(bool _limitRewardEnable) external onlyRole(EDITOR_ROLE) {
    limitRewardEnable = _limitRewardEnable;
  }

  function updateStartAndEndTimes(uint256 _startTime, uint256 _endTime) external onlyRole(EDITOR_ROLE) {
    require(_startTime < _endTime, "Invalid start and end time");
    endTime = _endTime;

    if (_startTime > block.timestamp) {
      startTime = _startTime;
    }
    emit ENewStartAndEndTimes(_startTime, _endTime);
  }

  function updateFreezeTimes(uint256 _freezeStartTime, uint256 _freezeEndTime) external onlyRole(EDITOR_ROLE) {
    require(_freezeStartTime < _freezeEndTime, "Invalid start and end time");
    require(block.timestamp < _freezeStartTime, "Invalid start and current");

    freezeStartTime = _freezeStartTime;
    freezeEndTime = _freezeEndTime;
    emit ENewFreezeTimes(freezeStartTime, freezeEndTime);
  }

  function updateNFTConfig(
    address _nftToken,
    uint256 _nftPkgId,
    uint256 _nftTokenId,
    uint256 _nftStakedRequired
  ) external onlyRole(EDITOR_ROLE) {
    nftToken = _nftToken;
    nftPkgId = _nftPkgId;
    nftTokenId = _nftTokenId;
    nftStakedRequired = _nftStakedRequired;
  }

  function updateToken(IERC20MetadataUpgradeable _stakedToken, IERC20MetadataUpgradeable _rewardToken)
    external
    onlyRole(EDITOR_ROLE)
  {
    stakedToken = _stakedToken;
    rewardToken = _rewardToken;
  }

  function deposit(uint256 _amount) external nonReentrant {
    require(block.timestamp >= startTime && block.timestamp <= endTime, "No deposit time");
    require(!isFrozen(), "isFrozen");
    if (maxStakedPerPool > 0) {
      require((currentStakedPerPool + _amount) <= maxStakedPerPool, "MaxStakedPerPool");
    }
    address sender = _msgSender();
    UserInfo storage user = userInfo[sender];

    if (!user.registered) {
      userList.push(sender);
      user.registered = true;
      user.addr = sender;
      user.amount = 0;
      user.claimed = 0;
      user.depositId = 0;
    }

    uint256 addedAmount;
    if (_amount > 0) {
      // Check real amount to avoid taxed token
      uint256 previousBalance = stakedToken.balanceOf(address(this));
      stakedToken.safeTransferFrom(address(sender), address(this), _amount);
      uint256 newBalance = stakedToken.balanceOf(address(this));
      addedAmount = newBalance - previousBalance;

      user.amount += addedAmount;
      currentStakedPerPool += addedAmount;
    }
    require(addedAmount > 0, "Invalid amount");

    depositInfos[sender][user.depositId] = DepositInfo(
      user.depositId,
      addedAmount,
      0,
      block.timestamp,
      block.timestamp + lockDuration,
      fixedAPY,
      block.timestamp,
      block.timestamp
    );
    user.depositId++;

    // Mint nft
    if (nftStakedRequired > 0) {
      uint256 amountNFT = (nftStakedProgress[sender] + addedAmount) / nftStakedRequired;
      nftStakedProgress[sender] = (nftStakedProgress[sender] + addedAmount) % nftStakedRequired;
      if (amountNFT > 0) {
        nftMintedCounter[sender] += amountNFT;
        uint256 nftIdTo = nftTokenId + amountNFT - 1;
        IMultiMintNFT(nftToken).multipleMint(sender, nftTokenId, nftIdTo, nftPkgId);
        emit EMintNFT(sender, nftTokenId, nftIdTo, nftPkgId);
        nftTokenId = nftIdTo + 1;
      }
    }

    // Reward needed
    poolRewardNeeded += estMaxReward(addedAmount, fixedAPY, lockDuration);
    if (limitRewardEnable) {
      require(getRemainingReward() >= poolRewardNeeded, "Insufficient rewards");
    }

    // Logs
    _addLog(sender, _amount, addedAmount, true);
    emit EDeposit(sender, user.depositId - 1, addedAmount);
  }

  function withdraw(uint256 _depositId) external nonReentrant {
    require(!isFrozen(), "isFrozen");
    address sender = _msgSender();
    DepositInfo storage userDeposit = depositInfos[sender][_depositId];
    require(block.timestamp > userDeposit.lockedTo, "Locked");
    require(userDeposit.amount > 0, "Empty");

    // Pending reward
    uint256 pending = getPendingReward(sender, _depositId);
    userInfo[sender].claimed += pending;
    claimedRewardPerPool += pending;
    rewardToken.safeTransfer(sender, pending);
    poolRewardNeeded -= pending;

    // Transfer staked token
    uint256 amount = userDeposit.amount;
    userInfo[sender].amount -= amount;
    stakedToken.safeTransfer(sender, amount);

    // Update deposit info
    userDeposit.amount = 0;
    userDeposit.reward = pending;
    userDeposit.lastRewardTime = block.timestamp;
    currentStakedPerPool -= amount;

    _addLog(sender, amount, pending, false);
    emit EWithdraw(sender, _depositId, amount);
  }

  function _addLog(
    address _addr,
    uint256 _amount1,
    uint256 _amount2,
    bool _isDeposit
  ) private {
    _logRecords.push(LogRecord(_addr, _amount1, _amount2, _isDeposit, block.timestamp));
  }

  function _getMultiplier(
    uint256 _from,
    uint256 _to,
    uint256 _startTime,
    uint256 _endTime
  ) private pure returns (uint256) {
    if (_from < _startTime) _from = _startTime;
    if (_to > _endTime) _to = _endTime;
    if (_from >= _to) return 0;
    return _to - _from;
  }
}