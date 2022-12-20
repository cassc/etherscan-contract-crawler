// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IMultiFeeDistribution.sol";
import "./interfaces/IOnwardIncentivesController.sol";
import "./interfaces/IChefIncentivesController.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract IncentivesControllerV2 is Ownable {
  using SafeMath for uint;
  using SafeERC20 for IERC20;

  // Info of each user.
  struct UserInfo {
    uint amount;
    uint rewardDebt;
  }
  // Info of each pool.
  struct PoolInfo {
    uint totalSupply;
    uint allocPoint; // How many allocation points assigned to this pool.
    uint lastRewardTime; // Last second that reward distribution occurs.
    uint accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
    IOnwardIncentivesController onwardIncentives;
  }
  // Info about token emissions for a given time period.
  struct EmissionPoint {
    uint128 startTimeOffset;
    uint128 rewardsPerSecond;
  }

  address public poolConfigurator;

  IMultiFeeDistribution public rewardMinter;
  IChefIncentivesController public immutable incentivesController;
  uint public rewardsPerSecond;
  uint public immutable maxMintableTokens;
  uint public mintedTokens;

  // Info of each pool.
  address[] public registeredTokens;
  mapping(address => PoolInfo) public poolInfo;

  // Data about the future reward rates. emissionSchedule stored in reverse chronological order,
  // whenever the number of blocks since the start block exceeds the next block offset a new
  // reward rate is applied.
  EmissionPoint[] public emissionSchedule;
  // token => user => Info of each user that stakes LP tokens.
  mapping(address => mapping(address => UserInfo)) private _userInfo;
  // user => base claimable balance
  mapping(address => uint) private _userBaseClaimable;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint public totalAllocPoint = 0;
  // The block number when reward mining starts.
  uint public startTime;

  // account earning rewards => receiver of rewards for this account
  // if receiver is set to address(0), rewards are paid to the earner
  // this is used to aid 3rd party contract integrations
  mapping (address => address) public claimReceiver;

  event BalanceUpdated(
    address indexed token,
    address indexed user,
    uint balance,
    uint totalSupply
  );

  bool private setuped;
  mapping(address => mapping(address => bool)) private userInitiated;
  mapping(address => bool) private userBaseClaimableInitiated;

  constructor(
    uint128[] memory _startTimeOffset,
    uint128[] memory _rewardsPerSecond,
    address _poolConfigurator,
    IMultiFeeDistribution _rewardMinter,
    uint _maxMintable,
    IChefIncentivesController _incentivesController
  ) {
    poolConfigurator = _poolConfigurator;
    rewardMinter = _rewardMinter;
    uint length = _startTimeOffset.length;
    for (uint i = length; i > 0; i--) {
      emissionSchedule.push(
        EmissionPoint({
          startTimeOffset: _startTimeOffset[i - 1],
          rewardsPerSecond: _rewardsPerSecond[i - 1]
        })
      );
    }
    maxMintableTokens = _maxMintable;
    incentivesController = _incentivesController;
  }

  // Start the party
  function start() public onlyOwner {
    require(startTime == 0);
    startTime = block.timestamp;
  }

  // Add a new lp to the pool. Can only be called by the poolConfigurator.
  function addPool(address _token, uint _allocPoint) external {
    require(msg.sender == poolConfigurator);
    require(poolInfo[_token].lastRewardTime == 0);
    _updateEmissions();
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    registeredTokens.push(_token);
    poolInfo[_token] = PoolInfo({
      totalSupply: 0,
      allocPoint: _allocPoint,
      lastRewardTime: block.timestamp,
      accRewardPerShare: 0,
      onwardIncentives: IOnwardIncentivesController(address(0))
    });
  }

  // Update the given pool's allocation point. Can only be called by the owner.
  function batchUpdateAllocPoint(
    address[] calldata _tokens,
    uint[] calldata _allocPoints
  ) public onlyOwner {
    require(_tokens.length == _allocPoints.length);
    _massUpdatePools();
    uint _totalAllocPoint = totalAllocPoint;
    for (uint i = 0; i < _tokens.length; i++) {
      PoolInfo storage pool = poolInfo[_tokens[i]];
      require(pool.lastRewardTime > 0);
      _totalAllocPoint = _totalAllocPoint.sub(pool.allocPoint).add(_allocPoints[i]);
      pool.allocPoint = _allocPoints[i];
    }
    totalAllocPoint = _totalAllocPoint;
  }

  function setOnwardIncentives(
    address _token,
    IOnwardIncentivesController _incentives
  )
    external
    onlyOwner
  {
    require(poolInfo[_token].lastRewardTime != 0);
    poolInfo[_token].onwardIncentives = _incentives;
  }

  function setClaimReceiver(address _user, address _receiver) external {
    require(msg.sender == _user || msg.sender == owner());
    claimReceiver[_user] = _receiver;
  }

  function poolLength() external view returns (uint) {
    return registeredTokens.length;
  }

  function claimableReward(address _user, address[] calldata _tokens)
    external
    view
    returns (uint[] memory)
  {
    uint[] memory claimable = new uint[](_tokens.length);
    for (uint i = 0; i < _tokens.length; i++) {
      address token = _tokens[i];
      PoolInfo memory pool = poolInfo[token];
      UserInfo memory user = userInfo(token, _user);
      uint accRewardPerShare = pool.accRewardPerShare;
      uint lpSupply = pool.totalSupply;
      if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
        uint duration = block.timestamp.sub(pool.lastRewardTime);
        uint reward = duration.mul(rewardsPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
        accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(lpSupply));
      }
      claimable[i] = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }
    return claimable;
  }

  function _updateEmissions() internal {
    uint length = emissionSchedule.length;
    if (startTime > 0 && length > 0) {
      EmissionPoint memory e = emissionSchedule[length-1];
      if (block.timestamp.sub(startTime) > e.startTimeOffset) {
        _massUpdatePools();
        rewardsPerSecond = uint(e.rewardsPerSecond);
        emissionSchedule.pop();
      }
    }
  }

  // Update reward variables for all pools
  function _massUpdatePools() internal {
    uint totalAP = totalAllocPoint;
    uint length = registeredTokens.length;
    for (uint i = 0; i < length; ++i) {
      _updatePool(poolInfo[registeredTokens[i]], totalAP);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function _updatePool(PoolInfo storage pool, uint _totalAllocPoint) internal {
    if (block.timestamp <= pool.lastRewardTime) {
      return;
    }
    uint lpSupply = pool.totalSupply;
    if (lpSupply == 0) {
      pool.lastRewardTime = block.timestamp;
      return;
    }
    uint duration = block.timestamp.sub(pool.lastRewardTime);
    uint reward = duration.mul(rewardsPerSecond).mul(pool.allocPoint).div(_totalAllocPoint);
    pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(lpSupply));
    pool.lastRewardTime = block.timestamp;
  }

  function _mint(address _user, uint _amount) internal {
    uint minted = mintedTokens;
    if (minted.add(_amount) > maxMintableTokens) {
      _amount = maxMintableTokens.sub(minted);
    }
    if (_amount > 0) {
      mintedTokens = minted.add(_amount);
      address receiver = claimReceiver[_user];
      if (receiver == address(0)) receiver = _user;
      rewardMinter.mint(receiver, _amount);
    }
  }

  function handleAction(address _user, uint _balance, uint _totalSupply) external {
    PoolInfo storage pool = poolInfo[msg.sender];
    require(pool.lastRewardTime > 0);
    _updateEmissions();
    _updatePool(pool, totalAllocPoint);
    UserInfo memory info = userInfo(msg.sender, _user);
    UserInfo storage user = _userInfo[msg.sender][_user];
    uint amount = info.amount;
    uint accRewardPerShare = pool.accRewardPerShare;
    if (amount > 0) {
      uint pending = amount.mul(accRewardPerShare).div(1e12).sub(info.rewardDebt);
      if (pending > 0) {
        _userBaseClaimable[_user] = userBaseClaimable(_user).add(pending);
      }
    }
    user.amount = _balance;
    user.rewardDebt = _balance.mul(accRewardPerShare).div(1e12);
    pool.totalSupply = _totalSupply;
    if (pool.onwardIncentives != IOnwardIncentivesController(address(0))) {
      pool.onwardIncentives.handleAction(msg.sender, _user, _balance, _totalSupply);
    }
    emit BalanceUpdated(msg.sender, _user, _balance, _totalSupply);
    if (!userInitiated[msg.sender][_user]) {
      userInitiated[msg.sender][_user] = true;
    }
    userBaseClaimableInitiated[_user] = true;
  }

  // Claim pending rewards for one or more pools.
  // Rewards are not received directly, they are minted by the rewardMinter.
  function claim(address _user, address[] calldata _tokens) external {
    _updateEmissions();
    uint pending = userBaseClaimable(_user);
    userBaseClaimableInitiated[_user] = true;
    _userBaseClaimable[_user] = 0;
    uint _totalAllocPoint = totalAllocPoint;
    for (uint i = 0; i < _tokens.length; i++) {
      PoolInfo storage pool = poolInfo[_tokens[i]];
      require(pool.lastRewardTime > 0);
      _updatePool(pool, _totalAllocPoint);
      UserInfo storage user = _userInfo[_tokens[i]][_user];
      UserInfo memory info = userInfo(_tokens[i], _user);
      uint rewardDebt = info.amount.mul(pool.accRewardPerShare).div(1e12);
      pending = pending.add(rewardDebt.sub(info.rewardDebt));
      user.rewardDebt = rewardDebt;
    }
    _mint(_user, pending);
  }

  function userBaseClaimable(address user) public view returns (uint) {
    if (userBaseClaimableInitiated[user]) {
      return _userBaseClaimable[user];
    } else {
      return incentivesController.userBaseClaimable(user);
    }
  }

  function userInfo(address token, address user) public view returns (UserInfo memory) {
    if (userInitiated[token][user]) {
      return _userInfo[token][user];
    } else {
      IChefIncentivesController.UserInfo memory info = incentivesController.userInfo(token, user);
      return UserInfo(info.amount, info.rewardDebt);
    }
  }

  function setup() external onlyOwner {
    require(!setuped, "already setuped");
    uint length = incentivesController.poolLength();
    for (uint i = 0; i < length; i++) {
      address token = incentivesController.registeredTokens(i);
      IChefIncentivesController.PoolInfo memory oldInfo = incentivesController.poolInfo(token);
      poolInfo[token] = PoolInfo(
        oldInfo.totalSupply,
        oldInfo.allocPoint,
        oldInfo.lastRewardTime,
        oldInfo.accRewardPerShare,
        oldInfo.onwardIncentives
      );
      registeredTokens.push(token);
      totalAllocPoint = totalAllocPoint.add(poolInfo[token].allocPoint);
    }
    startTime = incentivesController.startTime();
    rewardsPerSecond = incentivesController.rewardsPerSecond();
    mintedTokens = incentivesController.mintedTokens();
    setuped = true;
  }
}