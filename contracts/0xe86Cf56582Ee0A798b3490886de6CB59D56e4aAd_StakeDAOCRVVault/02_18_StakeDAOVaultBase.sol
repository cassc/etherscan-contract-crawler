// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/IStakeDAOGauge.sol";
import "./interfaces/IStakeDAOLockerProxy.sol";
import "./interfaces/IStakeDAOVault.sol";

import "../../common/FeeCustomization.sol";

// solhint-disable not-rely-on-time

abstract contract StakeDAOVaultBase is OwnableUpgradeable, FeeCustomization, IStakeDAOVault {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  /// @notice Emitted when the fee information is updated.
  /// @param _platform The address of platform contract.
  /// @param _platformPercentage The new platform fee percentage.
  /// @param _bountyPercentage The new harvest bounty fee percentage.
  /// @param _boostPercentage The new veSDT boost fee percentage.
  /// @param _withdrawPercentage The new withdraw fee percentage.
  event UpdateFeeInfo(
    address indexed _platform,
    uint32 _platformPercentage,
    uint32 _bountyPercentage,
    uint32 _boostPercentage,
    uint32 _withdrawPercentage
  );

  /// @notice Emitted when the length of reward period is updated.
  /// @param _token The address of token updated.
  /// @param _period The new reward period.
  event UpdateRewardPeriod(address indexed _token, uint32 _period);

  /// @notice Emitted when owner take withdraw fee from contract.
  /// @param _amount The amount of fee withdrawn.
  event TakeWithdrawFee(uint256 _amount);

  /// @dev Compiler will pack this into two `uint256`.
  struct RewardData {
    // The current reward rate per second.
    uint128 rate;
    // The length of reward period in seconds.
    // If the value is zero, the reward will be distributed immediately.
    uint32 periodLength;
    // The timesamp in seconds when reward is updated.
    uint48 lastUpdate;
    // The finish timestamp in seconds of current reward period.
    uint48 finishAt;
    // The accumulated acrv reward per share, with 1e9 precision.
    uint256 accRewardPerShare;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct FeeInfo {
    // The address of recipient of platform fee
    address platform;
    // The percentage of rewards to take for platform on harvest, multipled by 1e7.
    uint24 platformPercentage;
    // The percentage of rewards to take for caller on harvest, multipled by 1e7.
    uint24 bountyPercentage;
    // The percentage of rewards to take for veSDT boost on harvest, multipled by 1e7.
    uint24 boostPercentage;
    // The percentage of staked token to take on withdraw, multipled by 1e7.
    uint24 withdrawPercentage;
  }

  struct UserInfo {
    // The total amount of staking token deposited.
    uint256 balance;
    // Mapping from reward token address to pending rewards.
    mapping(address => uint256) rewards;
    // Mapping from reward token address to reward per share paid.
    mapping(address => uint256) rewardPerSharePaid;
  }

  /// @dev The type for withdraw fee, used in FeeCustomization.
  bytes32 internal constant WITHDRAW_FEE_TYPE = keccak256("StakeDAOVaultBase.WithdrawFee");

  /// @dev The denominator used for reward calculation.
  uint256 private constant REWARD_PRECISION = 1e18;

  /// @dev The maximum value of repay fee percentage.
  uint256 private constant MAX_WITHDRAW_FEE = 1e6; // 10%

  /// @dev The maximum value of veSDT boost fee percentage.
  uint256 private constant MAX_BOOST_FEE = 2e6; // 20%

  /// @dev The maximum value of platform fee percentage.
  uint256 private constant MAX_PLATFORM_FEE = 2e6; // 20%

  /// @dev The maximum value of harvest bounty percentage.
  uint256 private constant MAX_HARVEST_BOUNTY = 1e6; // 10%

  /// @dev The number of seconds in one week.
  uint256 internal constant WEEK = 86400 * 7;

  /// @dev The address of Stake DAO: SDT Token.
  address internal constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;

  /// @notice The address of StakeDaoLockerProxy contract.
  address public immutable stakeDAOProxy;

  /// @notice The address of VeSDTDelegation contract.
  address public immutable delegation;

  /// @notice The address of StakeDAO gauge.
  address public gauge;

  /// @notice The address of staking token.
  address public stakingToken;

  /// @notice The list of reward tokens from StakeDAO gauge.
  address[] public rewardTokens;

  /// @notice Mapping from reward token to reward information.
  mapping(address => RewardData) public rewardInfo;

  /// @inheritdoc IStakeDAOVault
  uint256 public override totalSupply;

  /// @dev Mapping from user address to user information.
  mapping(address => UserInfo) internal userInfo;

  /// @notice The accumulated amount of unclaimed withdraw fee.
  uint256 public withdrawFeeAccumulated;

  /// @notice The fee information, including platform fee, bounty fee and withdraw fee.
  FeeInfo public feeInfo;

  /********************************** Constructor **********************************/

  constructor(address _stakeDAOProxy, address _delegation) {
    stakeDAOProxy = _stakeDAOProxy;
    delegation = _delegation;
  }

  function _initialize(address _gauge) internal {
    OwnableUpgradeable.__Ownable_init();

    gauge = _gauge;
    stakingToken = IStakeDAOGauge(_gauge).staking_token();

    uint256 _count = IStakeDAOGauge(_gauge).reward_count();
    for (uint256 i = 0; i < _count; i++) {
      rewardTokens.push(IStakeDAOGauge(_gauge).reward_tokens(i));
    }
  }

  /********************************** View Functions **********************************/

  struct UserRewards {
    // The total amount of staking token deposited.
    uint256 balance;
    // The list of reward tokens
    address[] tokens;
    // The list of pending reward amounts.
    uint256[] rewards;
  }

  /// @notice Return aggregated user information for single user.
  /// @param _user The address of user to query.
  /// @return _info The aggregated user information to return.
  function getUserInfo(address _user) external view returns (UserRewards memory _info) {
    _info.balance = userInfo[_user].balance;

    uint256 _count = rewardTokens.length;
    _info.tokens = rewardTokens;
    _info.rewards = new uint256[](_count);
    for (uint256 i = 0; i < _count; i++) {
      _info.rewards[i] = userInfo[_user].rewards[_info.tokens[i]];
    }
  }

  /// @inheritdoc IStakeDAOVault
  function balanceOf(address _user) external view override returns (uint256) {
    return userInfo[_user].balance;
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IStakeDAOVault
  function deposit(uint256 _amount, address _recipient) external virtual override {
    address _token = stakingToken;
    if (_amount == uint256(-1)) {
      _amount = IERC20Upgradeable(_token).balanceOf(msg.sender);
    }
    require(_amount > 0, "deposit zero amount");

    IERC20Upgradeable(_token).safeTransferFrom(msg.sender, stakeDAOProxy, _amount);
    _deposit(_amount, _recipient);
  }

  /// @inheritdoc IStakeDAOVault
  function withdraw(uint256 _amount, address _recipient) external virtual override {
    _checkpoint(msg.sender);

    uint256 _balance = userInfo[_recipient].balance;
    if (_amount == uint256(-1)) {
      _amount = _balance;
    }
    require(_amount <= _balance, "insufficient staked token");
    require(_amount > 0, "withdraw zero amount");

    userInfo[_recipient].balance = _balance - _amount;
    totalSupply -= _amount;

    uint256 _withdrawFee = getFeeRate(WITHDRAW_FEE_TYPE, msg.sender);
    if (_withdrawFee > 0) {
      _withdrawFee = (_amount * _withdrawFee) / FEE_PRECISION;
      withdrawFeeAccumulated += _withdrawFee;
      _amount -= _withdrawFee;
    }

    IStakeDAOLockerProxy(stakeDAOProxy).withdraw(gauge, stakingToken, _amount, _recipient);

    emit Withdraw(msg.sender, _recipient, _amount, _withdrawFee);
  }

  /// @inheritdoc IStakeDAOVault
  function claim(address _user, address _recipient) external override returns (uint256[] memory _amounts) {
    if (_user != msg.sender) {
      require(_recipient == _user, "claim from others to others");
    }

    _checkpoint(_user);

    UserInfo storage _info = userInfo[_user];
    uint256 _count = rewardTokens.length;
    _amounts = new uint256[](_count);
    for (uint256 i = 0; i < _count; i++) {
      address _token = rewardTokens[i];
      _amounts[i] = _info.rewards[_token];
      if (_amounts[i] > 0) {
        IERC20Upgradeable(_token).safeTransfer(_recipient, _amounts[i]);
        _info.rewards[_token] = 0;
      }
    }

    emit Claim(_user, _recipient, _amounts);
  }

  /// @inheritdoc IStakeDAOVault
  function harvest(address _recipient) external override {
    // 1. checkpoint pending rewards
    _checkpoint(address(0));

    // 2. claim rewards from gauge
    address[] memory _tokens = rewardTokens;
    uint256[] memory _amounts = IStakeDAOLockerProxy(stakeDAOProxy).claimRewards(gauge, _tokens);

    // 3. distribute platform fee, harvest bounty and boost fee
    uint256[] memory _platformFees = new uint256[](_tokens.length);
    uint256[] memory _harvestBounties = new uint256[](_tokens.length);
    uint256 _boostFee;
    FeeInfo memory _fee = feeInfo;
    for (uint256 i = 0; i < _tokens.length; i++) {
      address _token = _tokens[i];
      if (_fee.platformPercentage > 0) {
        _platformFees[i] = (_amounts[i] * uint256(_fee.platformPercentage) * 100) / FEE_PRECISION;
        IERC20Upgradeable(_token).safeTransfer(_fee.platform, _platformFees[i]);
      }
      if (_fee.bountyPercentage > 0) {
        _harvestBounties[i] = (_amounts[i] * uint256(_fee.bountyPercentage) * 100) / FEE_PRECISION;
        IERC20Upgradeable(_token).safeTransfer(_recipient, _harvestBounties[i]);
      }
      if (_tokens[i] == SDT && _fee.boostPercentage > 0) {
        _boostFee = (_amounts[i] * uint256(_fee.boostPercentage) * 100) / FEE_PRECISION;
        IERC20Upgradeable(_token).safeTransfer(delegation, _boostFee);
      }
      _amounts[i] -= _platformFees[i] + _harvestBounties[i];
      if (_tokens[i] == SDT) {
        _amounts[i] -= _boostFee;
      }
    }

    emit Harvest(msg.sender, _amounts, _harvestBounties, _platformFees, _boostFee);

    // 4. distribute remaining rewards to users
    _distribute(_tokens, _amounts);
  }

  /// @inheritdoc IStakeDAOVault
  function checkpoint(address _user) external override {
    _checkpoint(_user);
  }

  /// @notice Helper function to reset reward tokens according to StakeDAO gauge.
  function resetRewardTokens() external {
    delete rewardTokens;

    address _gauge = gauge;
    uint256 _count = IStakeDAOGauge(_gauge).reward_count();
    for (uint256 i = 0; i < _count; i++) {
      rewardTokens.push(IStakeDAOGauge(_gauge).reward_tokens(i));
    }
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Withdraw and reset all pending withdraw fee from the contract.
  /// @param _recipient The address of recipient who will receive the withdraw fee.
  function takeWithdrawFee(address _recipient) external onlyOwner {
    uint256 _amount = withdrawFeeAccumulated;
    if (_amount > 0) {
      IStakeDAOLockerProxy(stakeDAOProxy).withdraw(gauge, stakingToken, _amount, _recipient);
      withdrawFeeAccumulated = 0;

      emit TakeWithdrawFee(_amount);
    }
  }

  /// @notice Update the fee information.
  /// @param _platform The platform address to be updated.
  /// @param _platformPercentage The platform fee percentage to be updated, multipled by 1e7.
  /// @param _bountyPercentage The harvest bounty percentage to be updated, multipled by 1e7.
  /// @param _boostPercentage The new veSDT boost fee percentage, multipled by 1e7.
  /// @param _withdrawPercentage The withdraw fee percentage to be updated, multipled by 1e7.
  function updateFeeInfo(
    address _platform,
    uint24 _platformPercentage,
    uint24 _bountyPercentage,
    uint24 _boostPercentage,
    uint24 _withdrawPercentage
  ) external onlyOwner {
    require(_platform != address(0), "zero address");
    require(_platformPercentage <= MAX_PLATFORM_FEE, "platform fee too large");
    require(_bountyPercentage <= MAX_HARVEST_BOUNTY, "bounty fee too large");
    require(_boostPercentage <= MAX_BOOST_FEE, "boost fee too large");
    require(_withdrawPercentage <= MAX_WITHDRAW_FEE, "withdraw fee too large");

    feeInfo = FeeInfo(_platform, _platformPercentage, _bountyPercentage, _boostPercentage, _withdrawPercentage);

    emit UpdateFeeInfo(_platform, _platformPercentage, _bountyPercentage, _boostPercentage, _withdrawPercentage);
  }

  /// @notice Update reward period length for some token.
  /// @param _token The address of token to update.
  /// @param _period The length of the period
  function updateRewardPeriod(address _token, uint32 _period) external onlyOwner {
    require(_period <= WEEK, "reward period too long");

    rewardInfo[_token].periodLength = _period;

    emit UpdateRewardPeriod(_token, _period);
  }

  /// @notice Update withdraw fee for certain user.
  /// @param _user The address of user to update.
  /// @param _percentage The withdraw fee percentage to be updated, multipled by 1e9.
  function setWithdrawFeeForUser(address _user, uint32 _percentage) external onlyOwner {
    require(_percentage <= MAX_WITHDRAW_FEE * 100, "withdraw fee too large");

    _setFeeCustomization(WITHDRAW_FEE_TYPE, _user, _percentage);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to update the user information.
  /// @param _user The address of user to update.
  /// @return _hasSDT Whether the reward tokens contain SDT.
  function _checkpoint(address _user) internal virtual returns (bool _hasSDT) {
    UserInfo storage _userInfo = userInfo[_user];
    uint256 _balance = _userInfo.balance;

    uint256 _count = rewardTokens.length;
    for (uint256 i = 0; i < _count; i++) {
      address _token = rewardTokens[i];
      _checkpoint(_token, _userInfo, _balance);

      if (_token == SDT) _hasSDT = true;
    }
  }

  /// @dev Internal function to update the user information for specific token.
  /// @param _token The address of token to update.
  /// @param _userInfo The UserInfor struct to update.
  /// @param _balance The total amount of staking token staked for the user.
  function _checkpoint(
    address _token,
    UserInfo storage _userInfo,
    uint256 _balance
  ) internal {
    RewardData memory _rewardInfo = rewardInfo[_token];
    if (_rewardInfo.periodLength > 0) {
      uint256 _currentTime = _rewardInfo.finishAt;
      if (_currentTime > block.timestamp) {
        _currentTime = block.timestamp;
      }
      uint256 _duration = _currentTime >= _rewardInfo.lastUpdate ? _currentTime - _rewardInfo.lastUpdate : 0;
      if (_duration > 0) {
        _rewardInfo.lastUpdate = uint48(block.timestamp);
        _rewardInfo.accRewardPerShare = _rewardInfo.accRewardPerShare.add(
          _duration.mul(_rewardInfo.rate).mul(REWARD_PRECISION) / totalSupply
        );

        rewardInfo[_token] = _rewardInfo;
      }
    }

    // update user information
    if (_balance > 0) {
      _userInfo.rewards[_token] = uint256(_userInfo.rewards[_token]).add(
        _rewardInfo.accRewardPerShare.sub(_userInfo.rewardPerSharePaid[_token]).mul(_balance) / REWARD_PRECISION
      );
      _userInfo.rewardPerSharePaid[_token] = _rewardInfo.accRewardPerShare;
    }
  }

  /// @dev Internal function to deposit staking token to proxy.
  /// @param _amount The amount of staking token to deposit.
  /// @param _recipient The address of recipient who will receive the deposited staking token.
  function _deposit(uint256 _amount, address _recipient) internal {
    _checkpoint(_recipient);

    uint256 _staked = IStakeDAOLockerProxy(stakeDAOProxy).deposit(gauge, stakingToken);
    require(_staked >= _amount, "staked amount mismatch");

    userInfo[_recipient].balance += _amount;
    totalSupply += _amount;

    emit Deposit(msg.sender, _recipient, _amount);
  }

  /// @dev Internal function to distribute new harvested rewards.
  /// @param _tokens The list of reward tokens to update.
  /// @param _amounts The list of corresponding reward token amounts.
  function _distribute(address[] memory _tokens, uint256[] memory _amounts) internal {
    uint256 _totalSupply = totalSupply;
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_amounts[i] == 0) continue;
      RewardData memory _info = rewardInfo[_tokens[i]];

      if (_info.periodLength == 0) {
        // distribute intermediately
        _info.accRewardPerShare = _info.accRewardPerShare.add(_amounts[i].mul(REWARD_PRECISION) / _totalSupply);
      } else {
        // distribute linearly
        if (block.timestamp >= _info.finishAt) {
          _info.rate = uint128(_amounts[i] / _info.periodLength);
        } else {
          uint256 _remaining = _info.finishAt - block.timestamp;
          uint256 _leftover = _remaining * _info.rate;
          _info.rate = uint128((_amounts[i] + _leftover) / _info.periodLength);
        }

        _info.lastUpdate = uint48(block.timestamp);
        _info.finishAt = uint48(block.timestamp + _info.periodLength);
      }

      rewardInfo[_tokens[i]] = _info;
    }
  }

  /// @inheritdoc FeeCustomization
  function _defaultFeeRate(bytes32) internal view override returns (uint256) {
    return uint256(feeInfo.withdrawPercentage) * 100;
  }
}