// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./AladdinConvexVault.sol";

interface ICTR {
  function mint(address _to, uint256 _value) external returns (bool);
}

contract ConcentratorIFOVault is AladdinConvexVault {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event ClaimCTR(uint256 indexed _pid, address indexed _caller, address _recipient, uint256 _amount);
  event IFOMineCTR(uint256 _amount);
  event UpdateIFOConfig(address _ctr, uint256 _startTime, uint256 _endTime);

  /// @dev The maximum amount of CTR to mint in IFO.
  uint256 private constant MAX_MINED_CTR = 2_500_000 ether;

  /// @dev The unlocked percentage of for CTR minted in IFO.
  uint256 private constant UNLOCK_PERCENTAGE = 1e9; // 100% will be unlocked to IFO miner.

  /// @dev The percentage CTR for liquidity mining.
  uint256 private constant LIQUIDITY_MINING_PERCENTAGE = 6e7;

  /// @notice Mapping from pool id to accumulated cont reward per share, with 1e18 precision.
  mapping(uint256 => uint256) public accCTRPerShare;

  /// @dev Mapping from pool id to account address to pending cont rewards.
  mapping(uint256 => mapping(address => uint256)) private userCTRRewards;

  /// @dev Mapping from pool id to account address to reward per share
  /// already paid for the user, with 1e18 precision.
  mapping(uint256 => mapping(address => uint256)) private userCTRPerSharePaid;

  /// @notice The address of $CTR token.
  address public ctr;

  /// @notice The start timestamp in seconds.
  uint64 public startTime;

  /// @notice The end timestamp in seconds.
  uint64 public endTime;

  /// @notice The amount of $CTR token mined so far.
  uint128 public ctrMined;

  /********************************** View Functions **********************************/

  /// @notice Return the amount of pending $CTR rewards for specific pool.
  /// @param _pid - The pool id.
  /// @param _account - The address of user.
  function pendingCTR(uint256 _pid, address _account) public view returns (uint256) {
    UserInfo storage _userInfo = userInfo[_pid][_account];
    return
      userCTRRewards[_pid][_account].add(
        accCTRPerShare[_pid].sub(userCTRPerSharePaid[_pid][_account]).mul(_userInfo.shares) / PRECISION
      );
  }

  /********************************** Mutated Functions **********************************/

  /// @notice Claim pending $CTR from specific pool.
  /// @param _pid - The pool id.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @return claimed - The amount of $CTR sent to caller.
  function claimCTR(uint256 _pid, address _recipient) external onlyExistPool(_pid) returns (uint256) {
    _updateRewards(_pid, msg.sender);

    uint256 _rewards = userCTRRewards[_pid][msg.sender];
    userCTRRewards[_pid][msg.sender] = 0;

    IERC20Upgradeable(ctr).safeTransfer(_recipient, _rewards);
    emit ClaimCTR(_pid, msg.sender, _recipient, _rewards);

    return _rewards;
  }

  /// @notice Claim pending $CTR from all pools.
  /// @param _recipient The address of recipient who will recieve the token.
  /// @return claimed - The amount of $CTR sent to caller.
  function claimAllCTR(address _recipient) external returns (uint256) {
    uint256 _rewards = 0;
    for (uint256 _pid = 0; _pid < poolInfo.length; _pid++) {
      UserInfo storage _userInfo = userInfo[_pid][msg.sender];

      // update if user has share
      if (_userInfo.shares > 0) {
        _updateRewards(_pid, msg.sender);
      }

      // claim if user has reward
      uint256 _currentPoolRewards = userCTRRewards[_pid][msg.sender];
      if (_currentPoolRewards > 0) {
        _rewards = _rewards.add(_currentPoolRewards);
        userCTRRewards[_pid][msg.sender] = 0;

        emit ClaimCTR(_pid, msg.sender, _recipient, _currentPoolRewards);
      }
    }

    IERC20Upgradeable(ctr).safeTransfer(_recipient, _rewards);

    return _rewards;
  }

  /// @notice See {AladdinConvexVault-harvest}
  function harvest(
    uint256 _pid,
    address _recipient,
    uint256 _minimumOut
  ) external override onlyExistPool(_pid) nonReentrant returns (uint256 harvested) {
    PoolInfo storage _pool = poolInfo[_pid];

    // 1. harvest and convert to aCRV
    uint256 _rewards;
    (harvested, _rewards) = _harvestAsACRV(_pid, _minimumOut);

    // 2. distribute harvest bounty to _recipient
    uint256 _harvestBounty = (_pool.harvestBountyPercentage * _rewards) / FEE_DENOMINATOR;
    if (_harvestBounty > 0) {
      _rewards = _rewards - _harvestBounty;
      IERC20Upgradeable(aladdinCRV).safeTransfer(_recipient, _harvestBounty);
    }

    // 3. do IFO if possible
    // solhint-disable-next-line not-rely-on-time
    if (startTime <= block.timestamp && block.timestamp <= endTime) {
      uint256 _pendingCTR = MAX_MINED_CTR - ctrMined;
      if (_pendingCTR > _rewards) {
        _pendingCTR = _rewards;
      }
      if (_pendingCTR > 0) {
        uint256 _unlocked = (_pendingCTR * UNLOCK_PERCENTAGE) / FEE_DENOMINATOR;
        accCTRPerShare[_pid] = accCTRPerShare[_pid].add(_unlocked.mul(PRECISION) / _pool.totalShare);

        ctrMined += uint128(_pendingCTR);

        // Vault Mining $CTR, unlocked part
        ICTR(ctr).mint(address(this), _unlocked);

        // Liquidity Mining $CTR and Vault Mining $CTR, locked part
        ICTR(ctr).mint(
          platform,
          (_pendingCTR * LIQUIDITY_MINING_PERCENTAGE) / FEE_DENOMINATOR + _pendingCTR - _unlocked
        );

        // transfer aCRV to platform
        IERC20Upgradeable(aladdinCRV).safeTransfer(platform, _pendingCTR);

        emit IFOMineCTR(_pendingCTR);
      }
      _rewards -= _pendingCTR;
    }

    // 4. distribute rest rewards to platform and depositors
    if (_rewards > 0) {
      uint256 _platformFee = _pool.platformFeePercentage;
      if (_platformFee > 0) {
        _platformFee = (_platformFee * _rewards) / FEE_DENOMINATOR;
        _rewards = _rewards - _platformFee;
        IERC20Upgradeable(aladdinCRV).safeTransfer(platform, _platformFee);
      }

      _pool.accRewardPerShare = _pool.accRewardPerShare.add(_rewards.mul(PRECISION) / _pool.totalShare);

      emit Harvest(msg.sender, _rewards, _platformFee, _harvestBounty);
    }
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update IFO configuration
  /// @param _ctr The address of $CTR token.
  /// @param _startTime The start time of IFO.
  /// @param _endTime The finish time of IFO.
  function updateIFOConfig(
    address _ctr,
    uint64 _startTime,
    uint64 _endTime
  ) external onlyOwner {
    require(_startTime <= _endTime, "invalid IFO time");

    ctr = _ctr;
    startTime = _startTime;
    endTime = _endTime;

    emit UpdateIFOConfig(_ctr, _startTime, _endTime);
  }

  /********************************** Internal Functions **********************************/

  function _updateRewards(uint256 _pid, address _account) internal override {
    // 1. update aCRV rewards
    AladdinConvexVault._updateRewards(_pid, _account);

    // 2. update CTR rewards
    uint256 _ctrRewards = pendingCTR(_pid, _account);
    userCTRRewards[_pid][_account] = _ctrRewards;
    userCTRPerSharePaid[_pid][_account] = accCTRPerShare[_pid];
  }

  function _harvestAsACRV(uint256 _pid, uint256 _minimumOut) internal returns (uint256, uint256) {
    PoolInfo storage _pool = poolInfo[_pid];
    address[] memory _rewardsToken = _pool.convexRewardTokens;
    uint256[] memory _balances = new uint256[](_rewardsToken.length);
    for (uint256 i = 0; i < _rewardsToken.length; i++) {
      _balances[i] = IERC20Upgradeable(_rewardsToken[i]).balanceOf(address(this));
    }
    // 1. claim rewards
    IConvexBasicRewards(_pool.crvRewards).getReward();

    // 2. swap all rewards token to CRV
    uint256 _amountETH;
    uint256 _amountCRV;
    address _token;
    address _zap = zap;
    for (uint256 i = 0; i < _rewardsToken.length; i++) {
      _token = _rewardsToken[i];
      _balances[i] = IERC20Upgradeable(_rewardsToken[i]).balanceOf(address(this)).sub(_balances[i]);
      if (_token != CRV) {
        if (_balances[i] > 0) {
          IERC20Upgradeable(_token).safeTransfer(_zap, _balances[i]);
          _amountETH = _amountETH.add(IZap(_zap).zap(_token, _balances[i], address(0), 0));
        }
      } else {
        _amountCRV += _balances[i];
      }
    }
    if (_amountETH > 0) {
      _amountCRV += IZap(_zap).zap{ value: _amountETH }(address(0), _amountETH, CRV, 0);
    }
    uint256 _amountCVXCRV = _swapCRVToCvxCRV(_amountCRV, _minimumOut);

    // 3. deposit cvxCRV as aCRV
    _token = aladdinCRV; // gas saving
    _approve(CVXCRV, _token, _amountCVXCRV);
    uint256 _rewards = IAladdinCRV(_token).deposit(address(this), _amountCVXCRV);

    return (_amountCVXCRV, _rewards);
  }
}