// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";
import "../interfaces/IStakingRewards.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingRewards is IStakingRewards, Ownable {
  using SafeERC20 for ERC20;
  using PRBMathUD60x18 for uint256;

  ERC20 public immutable override rewardToken;

  // Dao token => dao reward data
  mapping(address => RewardDistribution) public override daoRewards;
  // Dao token => user address => user stake data
  mapping(address => mapping(address => UserStake)) public override userStakes;

  uint256 public lockupPeriod;

  constructor(
    address _rewardToken,
    address _owner,
    uint256 _lockupPeriod
  ) {
    require(_rewardToken != address(0), "invalid reward token");
    rewardToken = ERC20(_rewardToken);
    lockupPeriod = _lockupPeriod;
    transferOwnership(_owner);
  }

  modifier isUnlocked(address _daoToken) {
    UserStake memory user = userStakes[_daoToken][msg.sender];
    require(
      block.timestamp >= user.timeStaked + lockupPeriod,
      "stake still locked"
    );
    _;
  }

  function setLockupPeriod(uint256 _lockupPeriod) external override onlyOwner {
    lockupPeriod = _lockupPeriod;
  }

  function stake(address _daoToken, uint256 _amount) external override {
    _processStake(msg.sender, _daoToken, _amount);
  }

  function stakeOnBehalf(
    address _user,
    address _daoToken,
    uint256 _amount
  ) external override {
    require(_user != address(0), "invalid user");
    _processStake(_user, _daoToken, _amount);
  }

  function unstake(
    address _daoToken,
    uint256 _amount,
    address _to
  ) external override isUnlocked(_daoToken) {
    require(_daoToken != address(0), "invalid token");
    require(_amount > 0, "invalid amount");
    require(_to != address(0), "invalid destination");

    RewardDistribution memory dao = daoRewards[_daoToken];
    UserStake memory user = userStakes[_daoToken][msg.sender];

    require(_amount <= user.stakedAmount, "invalid unstake amount");

    // Save their currently earned reward entitlement
    user.pendingRewards += _getRewardAmount(
      user.stakedAmount,
      dao.rewardPerToken,
      user.rewardEntry
    );

    user.stakedAmount -= _amount;
    user.rewardEntry = dao.rewardPerToken;
    dao.totalStake -= _amount;

    if (dao.totalStake == 0) {
      // Last man out the door resets the staking contract for that DAO.
      dao.rewardPerToken = 0;
    }

    daoRewards[_daoToken] = dao;
    userStakes[_daoToken][msg.sender] = user;

    emit Unstake(msg.sender, _daoToken, _amount);

    ERC20(_daoToken).safeTransfer(_to, _amount);
  }

  function claimRewards(address _daoToken, address _to) external override {
    require(_daoToken != address(0), "invalid dao token");
    require(_to != address(0), "invalid destination");

    RewardDistribution memory dao = daoRewards[_daoToken];
    UserStake memory user = userStakes[_daoToken][msg.sender];

    uint256 entitlement = _getRewardAmount(
      user.stakedAmount,
      dao.rewardPerToken,
      user.rewardEntry
    ) + user.pendingRewards;

    user.pendingRewards = 0;
    user.rewardEntry = dao.rewardPerToken;

    userStakes[_daoToken][msg.sender] = user;

    emit ClaimRewards(msg.sender, _daoToken, entitlement);

    rewardToken.safeTransfer(_to, entitlement);
  }

  function emergencyEject(address _daoToken, address _to)
    external
    override
    isUnlocked(_daoToken)
  {
    require(_daoToken != address(0), "invalid dao token");
    require(_to != address(0), "invalid destination");

    RewardDistribution memory dao = daoRewards[_daoToken];
    UserStake memory user = userStakes[_daoToken][msg.sender];

    uint256 entitlement = _getRewardAmount(
      user.stakedAmount,
      dao.rewardPerToken,
      user.rewardEntry
    ) + user.pendingRewards;

    uint256 ejectAmount = user.stakedAmount;
    user.stakedAmount = 0;
    user.rewardEntry = 0;
    user.pendingRewards = 0;
    dao.totalStake -= ejectAmount;

    if (dao.totalStake > 0) {
      // Distribute user's lost rewards to everyone else.
      dao.rewardPerToken = _calculateRewardPerToken(
        dao.rewardPerToken,
        entitlement,
        dao.totalStake
      );
    } else {
      // Last man out the door resets the dao
      dao.rewardPerToken = 0;
    }

    daoRewards[_daoToken] = dao;
    userStakes[_daoToken][msg.sender] = user;

    emit Eject(msg.sender, _daoToken, ejectAmount);

    ERC20(_daoToken).safeTransfer(_to, ejectAmount);
  }

  function distributeRewards(address _daoToken, uint256 _amount)
    external
    override
  {
    require(_daoToken != address(0), "invalid dao");
    require(_amount > 0, "invalid amount");

    RewardDistribution memory dao = daoRewards[_daoToken];

    if (dao.totalStake == 0) {
      dao.rewardPerToken += _amount;
    } else {
      dao.rewardPerToken = _calculateRewardPerToken(
        dao.rewardPerToken,
        _amount,
        dao.totalStake
      );
    }

    daoRewards[_daoToken] = dao;

    // Emit event
    emit Distribution(_daoToken, _amount);

    rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
  }

  function pendingRewards(address _user, address _daoToken)
    external
    view
    override
    returns (uint256 rewardAmount)
  {
    RewardDistribution memory dao = daoRewards[_daoToken];
    UserStake memory user = userStakes[_daoToken][_user];

    rewardAmount =
      _getRewardAmount(
        user.stakedAmount,
        dao.rewardPerToken,
        user.rewardEntry
      ) +
      user.pendingRewards;
  }

  /// ### Internal functions

  /// @notice Processes the stake for both stake and stake on behalf functions
  /// @param _user The user the tokens are being staked on behalf for
  /// @param _daoToken The governance token of the dao to be staked.
  /// @param _amount The amount of governance token to be staked
  function _processStake(
    address _user,
    address _daoToken,
    uint256 _amount
  ) internal {
    require(_daoToken != address(0), "invalid token");
    require(_amount > 0, "invalid amount");

    RewardDistribution memory dao = daoRewards[_daoToken];
    UserStake memory user = userStakes[_daoToken][_user];

    if (dao.totalStake == 0) {
      // Distribute reward amount equally across the first staker's tokens
      if (dao.rewardPerToken > 0) {
        user.pendingRewards = dao.rewardPerToken;
        dao.rewardPerToken = _calculateRewardPerToken(
          0,
          dao.rewardPerToken,
          _amount
        );
      }
    } else {
      user.pendingRewards += _getRewardAmount(
        user.stakedAmount,
        dao.rewardPerToken,
        user.rewardEntry
      );
    }

    user.rewardEntry = dao.rewardPerToken;
    user.stakedAmount += _amount;
    user.timeStaked = block.timestamp;
    dao.totalStake += _amount;

    daoRewards[_daoToken] = dao;
    userStakes[_daoToken][_user] = user;

    emit Stake(_user, _daoToken, _amount);

    ERC20(_daoToken).safeTransferFrom(msg.sender, address(this), _amount);
  }

  /// @notice Calculates the actual amount of reward token that a user is entitled to
  /// @param _userStake  The number of tokens a user has currently staked
  /// @param _rewardPerToken  The current reward per token A 60.18 fixed point number
  /// @param _userRewardEntry  The reward per token the last time the user modified their stake. A 60.18 fixed point number
  function _getRewardAmount(
    uint256 _userStake,
    uint256 _rewardPerToken,
    uint256 _userRewardEntry
  ) internal pure returns (uint256 rewardAmount) {
    if (_userStake == 0 || _rewardPerToken == _userRewardEntry) return 0;
    rewardAmount = PRBMathUD60x18.toUint(
      (_userStake.mul(_rewardPerToken) - (_userStake.mul(_userRewardEntry)))
    );
  }

  /// @notice Calculates the reward per token
  /// @param _currentRewardPerToken The current reward token per staked token
  /// @param _distribution  The amount to distribute
  /// @param _totalStake  The total amount of tokens staked
  function _calculateRewardPerToken(
    uint256 _currentRewardPerToken,
    uint256 _distribution,
    uint256 _totalStake
  ) internal pure returns (uint256 rewardPerToken) {
    rewardPerToken =
      _currentRewardPerToken +
      (PRBMathUD60x18.fromUint(_distribution).div(_totalStake));
  }
}