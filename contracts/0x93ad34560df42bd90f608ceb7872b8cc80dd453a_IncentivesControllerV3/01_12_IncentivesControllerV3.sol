// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./interfaces/IMultiFeeDistribution.sol";
import "./interfaces/IOnwardIncentivesController.sol";
import "./interfaces/IChefIncentivesController.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract IncentivesControllerV3 is Ownable {
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

  /// @notice The address of the pool configurator.
  address public poolConfigurator;
  /// @notice  The address of the reward minter.
  IMultiFeeDistribution public rewardMinter;
  /// @notice The address of the incentives controller.
  IChefIncentivesController public immutable incentivesController;
  /// @notice The amount of tokens to be minted per second.
  uint public rewardsPerSecond;
  /// @notice The maximum amount of tokens that can be minted.
  uint public maxMintableTokens;
  /// @notice The amount of tokens that have been minted.
  uint public mintedTokens;

  // Info of each pool.
  address[] public registeredTokens;
  /// @notice Info of each pool.
  mapping(address => PoolInfo) public poolInfo;

  // Data about the future reward rates. emissionSchedule stored in reverse chronological order,
  // whenever the number of blocks since the start block exceeds the next block offset a new
  // reward rate is applied.
  EmissionPoint[] public emissionSchedule;
  // token => user => Info of each user that stakes LP tokens.
  mapping(address => mapping(address => UserInfo)) public userInfo;
  // user => base claimable balance
  mapping(address => uint) public userBaseClaimable;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint public totalAllocPoint;
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

  event PoolAdded(
    address indexed token,
    uint allocPoint
  );

  event AllocPointUpdated(
    address indexed token,
    uint allocPoint
  );

  bool private setuped;
  mapping(address => mapping(address => bool)) private userInfoInitiated;
  mapping(address => bool) private userBaseClaimableInitiated;

  constructor(
    address _poolConfigurator,
    IMultiFeeDistribution _rewardMinter,
    IChefIncentivesController _incentivesController
  ) {
    require(_poolConfigurator != address(0), "pool configurator not set");
    require(address(_rewardMinter) != address(0), "reward minter not set");
    require(address(_incentivesController) != address(0), "incentives controller not set");
    poolConfigurator = _poolConfigurator;
    rewardMinter = _rewardMinter;
    incentivesController = _incentivesController;
  }

  // Add a new lp to the pool. Can only be called by the poolConfigurator.
  function addPool(address _token, uint _allocPoint) external {
    require(_token != address(0), "token cannot be zero address");
    require(msg.sender == poolConfigurator, "only pool configurator can add pools");
    require(poolInfo[_token].lastRewardTime == 0, "pool already registered");
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
    emit PoolAdded(_token, _allocPoint);
  }

  // Update the given pool's allocation point. Can only be called by the owner.
  function batchUpdateAllocPoint(
    address[] calldata _tokens,
    uint[] calldata _allocPoints
  ) external onlyOwner {
    require(_tokens.length == _allocPoints.length, "arrays not same length");
    _massUpdatePools();
    uint _totalAllocPoint = totalAllocPoint;
    for (uint i = 0; i < _tokens.length; i++) {
      PoolInfo storage pool = poolInfo[_tokens[i]];
      require(pool.lastRewardTime != 0, "pool not registered");
      _totalAllocPoint = _totalAllocPoint.sub(pool.allocPoint).add(_allocPoints[i]);
      pool.allocPoint = _allocPoints[i];
      emit AllocPointUpdated(_tokens[i], _allocPoints[i]);
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
    require(poolInfo[_token].lastRewardTime != 0, "pool not registered");
    poolInfo[_token].onwardIncentives = _incentives;
  }

  function setClaimReceiver(address _user, address _receiver) external {
    require(msg.sender == _user, "only user can set claim receiver");
    require(_receiver != address(0), "receiver cannot be zero address");
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
    uint256[] memory claimable = new uint256[](_tokens.length);
    for (uint256 i = 0; i < _tokens.length; i++) {
      address token = _tokens[i];
      PoolInfo memory pool = poolInfo[token];
      UserInfo memory user;
      if (userInfoInitiated[token][_user]) {
        user = userInfo[token][_user];
      } else {
        IChefIncentivesController.UserInfo memory userInfoV1 = incentivesController.userInfo(token, _user);
        user = UserInfo({
          amount: userInfoV1.amount,
          rewardDebt: userInfoV1.rewardDebt
        });
      }
      uint256 accRewardPerShare = pool.accRewardPerShare;
      uint256 lpSupply = pool.totalSupply;
      if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
        uint256 duration = block.timestamp.sub(pool.lastRewardTime);
        uint256 reward = duration.mul(rewardsPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
        accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(lpSupply));
      }
      claimable[i] = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
    }
    return claimable;
  }

  function _updateEmissions() internal {
    uint length = emissionSchedule.length;
    if (startTime != 0 && length != 0) {
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
    console.log('accRewardPerShare', pool.accRewardPerShare);
    pool.lastRewardTime = block.timestamp;
  }

  function _mint(address _user, uint _amount) internal {
    uint minted = mintedTokens;
    if (minted.add(_amount) > maxMintableTokens) {
      _amount = maxMintableTokens.sub(minted);
    }
    if (_amount != 0) {
      mintedTokens = minted.add(_amount);
      address receiver = claimReceiver[_user];
      if (receiver == address(0)) receiver = _user;
      rewardMinter.mint(receiver, _amount);
    }
  }

  /**
   * @notice Handle an action that has been triggered on a pool. (e.g. deposit/withdraw/borrow/repay)
   * @dev msg.sender is a token contract.
   * @param _user address of the user that triggered the action.
   * @param _balance balance of the user on the token contract.
   * @param _totalSupply total supply of the token contract.
   */
  function handleAction(address _user, uint _balance, uint _totalSupply) external {
    initiateUserInfo(_user, msg.sender);
    initiateUserBaseClaimable(_user);
    PoolInfo storage pool = poolInfo[msg.sender];
    require(pool.lastRewardTime != 0, "pool not registered");
    _updateEmissions();
    _updatePool(pool, totalAllocPoint);
    UserInfo storage user = userInfo[msg.sender][_user];
    uint256 amount = user.amount;
    uint256 accRewardPerShare = pool.accRewardPerShare;
    console.log("amount", amount);
    if (amount != 0) {
      uint256 pending = amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
      console.log("pending", pending, accRewardPerShare);
      if (pending != 0) {
        userBaseClaimable[_user] = userBaseClaimable[_user].add(pending);
      }
    }
    user.amount = _balance;
    user.rewardDebt = _balance.mul(accRewardPerShare).div(1e12);
    pool.totalSupply = _totalSupply;
    if (pool.onwardIncentives != IOnwardIncentivesController(address(0))) {
      pool.onwardIncentives.handleAction(msg.sender, _user, _balance, _totalSupply);
    }
    emit BalanceUpdated(msg.sender, _user, _balance, _totalSupply);
  }

  function initiateUserBaseClaimable(address user) internal {
    if(!userBaseClaimableInitiated[user]) {
      userBaseClaimable[user] = incentivesController.userBaseClaimable(user);
      userBaseClaimableInitiated[user] = true;
    }
  }

  function initiateUserInfo(address user, address token) internal {
    if(!userInfoInitiated[token][user]) {
      IChefIncentivesController.UserInfo memory userInfoPrev = incentivesController.userInfo(token, user);
      userInfo[token][user] = UserInfo({
        amount: userInfoPrev.amount,
        rewardDebt: userInfoPrev.rewardDebt
      });
      userInfoInitiated[token][user] = true;
    }
  }

  // Claim pending rewards for one or more pools.
  // Rewards are not received directly, they are minted by the rewardMinter.
  function claim(address _user, address[] calldata _tokens) external {
    for (uint i = 0; i < _tokens.length; i++) {
      initiateUserInfo(_user, _tokens[i]);
    }
    initiateUserBaseClaimable(_user);
    _updateEmissions();
    uint256 pending = userBaseClaimable[_user];
    userBaseClaimable[_user] = 0;
    for (uint i = 0; i < _tokens.length; i++) {
      PoolInfo storage pool = poolInfo[_tokens[i]];
      require(pool.lastRewardTime != 0, "pool not registered");
      _updatePool(pool, totalAllocPoint);
      UserInfo storage user = userInfo[_tokens[i]][_user];
      uint256 rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
      pending = pending.add(rewardDebt.sub(user.rewardDebt));
      user.rewardDebt = rewardDebt;
    }
    _mint(_user, pending);
  }

  function setRewardMinter(IMultiFeeDistribution _miner) external onlyOwner {
    rewardMinter = _miner;
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
    _copyEmissionSchedule();
    startTime = incentivesController.startTime();
    rewardsPerSecond = incentivesController.rewardsPerSecond();
    mintedTokens = incentivesController.mintedTokens();
    maxMintableTokens = incentivesController.maxMintableTokens();
    setuped = true;
  }

  function _copyEmissionSchedule() internal {
    uint256 idx;
    do {
      try incentivesController.emissionSchedule(idx) returns (IChefIncentivesController.EmissionPoint memory _point) {
        emissionSchedule.push(EmissionPoint(_point.startTimeOffset, _point.rewardsPerSecond));
        idx++;
      } catch  {
        break;
      }
    } while (true);
  }
}