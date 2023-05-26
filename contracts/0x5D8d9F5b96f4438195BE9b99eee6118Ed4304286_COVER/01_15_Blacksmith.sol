// SPDX-License-Identifier: None
pragma solidity ^0.7.4;

import "./ERC20/IERC20.sol";
import "./ERC20/SafeERC20.sol";
import "./utils/SafeMath.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./interfaces/ICOVER.sol";
import "./interfaces/IBlacksmith.sol";

/**
 * @title COVER token shield mining contract
 * @author [email protected]
 */
contract Blacksmith is Ownable, IBlacksmith, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ICOVER public cover;
  address public governance;
  address public treasury;
  /// @notice Total 17k COVER in 1st 6 mths. TODO: update to 246e18 after 6 months from 1605830400 (11/20/2020 12am UTC)
  uint256 public weeklyTotal = 654e18;
  uint256 public totalWeight; // total weight for all pools
  uint256 public constant START_TIME = 1605830400; // 11/20/2020 12am UTC
  uint256 public constant WEEK = 7 days;
  uint256 private constant CAL_MULTIPLIER = 1e12; // help calculate rewards/bonus PerToken only. 1e12 will allow meaningful $1 deposit in a $1bn pool
  address[] public poolList;
  mapping(address => Pool) public pools; // lpToken => Pool
  mapping(address => BonusToken) public bonusTokens; // lpToken => BonusToken
  // bonusToken => 1 (allowed), allow anyone to use the bonus token to run a bonus program on any pool
  mapping(address => uint8) public allowBonusTokens;
  // lpToken => Miner address => Miner data
  mapping(address => mapping(address => Miner)) public miners;

  modifier onlyGovernance() {
    require(msg.sender == governance, "Blacksmith: caller not governance");
    _;
  }

  constructor (address _coverAddress, address _governance, address _treasury) {
    cover = ICOVER(_coverAddress);
    governance = _governance;
    treasury = _treasury;
  }

  function getPoolList() external view override returns (address[] memory) {
    return poolList;
  }

  function viewMined(address _lpToken, address _miner)
   external view override returns (uint256 _minedCOVER, uint256 _minedBonus)
  {
    Pool memory pool = pools[_lpToken];
    Miner memory miner = miners[_lpToken][_miner];
    uint256 lpTotal = IERC20(_lpToken).balanceOf(address(this));
    if (miner.amount > 0 && lpTotal > 0) {
      uint256 coverRewards = _calculateCoverRewardsForPeriod(pool);
      uint256 accRewardsPerToken = pool.accRewardsPerToken.add(coverRewards.div(lpTotal));
      _minedCOVER = miner.amount.mul(accRewardsPerToken).div(CAL_MULTIPLIER).sub(miner.rewardWriteoff);

      BonusToken memory bonusToken = bonusTokens[_lpToken];
      if (bonusToken.startTime < block.timestamp && bonusToken.totalBonus > 0) {
        uint256 bonus = _calculateBonusForPeriod(bonusToken);
        uint256 accBonusPerToken = bonusToken.accBonusPerToken.add(bonus.div(lpTotal));
        _minedBonus = miner.amount.mul(accBonusPerToken).div(CAL_MULTIPLIER).sub(miner.bonusWriteoff);
      }
    }
    return (_minedCOVER, _minedBonus);
  }

  /// @notice update pool's rewards & bonus per staked token till current block timestamp
  function updatePool(address _lpToken) public override {
    Pool storage pool = pools[_lpToken];
    if (block.timestamp <= pool.lastUpdatedAt) return;
    uint256 lpTotal = IERC20(_lpToken).balanceOf(address(this));
    if (lpTotal == 0) {
      pool.lastUpdatedAt = block.timestamp;
      return;
    }
    // update COVER rewards for pool
    uint256 coverRewards = _calculateCoverRewardsForPeriod(pool);
    pool.accRewardsPerToken = pool.accRewardsPerToken.add(coverRewards.div(lpTotal));
    pool.lastUpdatedAt = block.timestamp;
    // update bonus token rewards if exist for pool
    BonusToken storage bonusToken = bonusTokens[_lpToken];
    if (bonusToken.lastUpdatedAt < bonusToken.endTime && bonusToken.startTime < block.timestamp) {
      uint256 bonus = _calculateBonusForPeriod(bonusToken);
      bonusToken.accBonusPerToken = bonusToken.accBonusPerToken.add(bonus.div(lpTotal));
      bonusToken.lastUpdatedAt = block.timestamp <= bonusToken.endTime ? block.timestamp : bonusToken.endTime;
    }
  }

  function claimRewards(address _lpToken) public override {
    updatePool(_lpToken);

    Pool memory pool = pools[_lpToken];
    Miner storage miner = miners[_lpToken][msg.sender];
    BonusToken memory bonusToken = bonusTokens[_lpToken];

    _claimCoverRewards(pool, miner);
    _claimBonus(bonusToken, miner);
    // update writeoff to match current acc rewards & bonus per token
    miner.rewardWriteoff = miner.amount.mul(pool.accRewardsPerToken).div(CAL_MULTIPLIER);
    miner.bonusWriteoff = miner.amount.mul(bonusToken.accBonusPerToken).div(CAL_MULTIPLIER);
  }

  function claimRewardsForPools(address[] calldata _lpTokens) external override {
    for (uint256 i = 0; i < _lpTokens.length; i++) {
      claimRewards(_lpTokens[i]);
    }
  }

  function deposit(address _lpToken, uint256 _amount) external override {
    require(block.timestamp >= START_TIME , "Blacksmith: not started");
    require(_amount > 0, "Blacksmith: amount is 0");
    Pool memory pool = pools[_lpToken];
    require(pool.lastUpdatedAt > 0, "Blacksmith: pool does not exists");
    require(IERC20(_lpToken).balanceOf(msg.sender) >= _amount, "Blacksmith: insufficient balance");
    updatePool(_lpToken);

    Miner storage miner = miners[_lpToken][msg.sender];
    BonusToken memory bonusToken = bonusTokens[_lpToken];
    _claimCoverRewards(pool, miner);
    _claimBonus(bonusToken, miner);

    miner.amount = miner.amount.add(_amount);
    // update writeoff to match current acc rewards/bonus per token
    miner.rewardWriteoff = miner.amount.mul(pool.accRewardsPerToken).div(CAL_MULTIPLIER);
    miner.bonusWriteoff = miner.amount.mul(bonusToken.accBonusPerToken).div(CAL_MULTIPLIER);

    IERC20(_lpToken).safeTransferFrom(msg.sender, address(this), _amount);
    emit Deposit(msg.sender, _lpToken, _amount);
  }

  function withdraw(address _lpToken, uint256 _amount) external override {
    require(_amount > 0, "Blacksmith: amount is 0");
    Miner storage miner = miners[_lpToken][msg.sender];
    require(miner.amount >= _amount, "Blacksmith: insufficient balance");
    updatePool(_lpToken);

    Pool memory pool = pools[_lpToken];
    BonusToken memory bonusToken = bonusTokens[_lpToken];
    _claimCoverRewards(pool, miner);
    _claimBonus(bonusToken, miner);

    miner.amount = miner.amount.sub(_amount);
    // update writeoff to match current acc rewards/bonus per token
    miner.rewardWriteoff = miner.amount.mul(pool.accRewardsPerToken).div(CAL_MULTIPLIER);
    miner.bonusWriteoff = miner.amount.mul(bonusToken.accBonusPerToken).div(CAL_MULTIPLIER);

    _safeTransfer(_lpToken, _amount);
    emit Withdraw(msg.sender, _lpToken, _amount);
  }

  /// @notice withdraw all without rewards
  function emergencyWithdraw(address _lpToken) external override {
    Miner storage miner = miners[_lpToken][msg.sender];
    uint256 amount = miner.amount;
    require(miner.amount > 0, "Blacksmith: insufficient balance");
    miner.amount = 0;
    miner.rewardWriteoff = 0;
    _safeTransfer(_lpToken, amount);
    emit Withdraw(msg.sender, _lpToken, amount);
  }

  /// @notice update pool weights
  function updatePoolWeights(address[] calldata _lpTokens, uint256[] calldata _weights) public override onlyGovernance {
    for (uint256 i = 0; i < _lpTokens.length; i++) {
      Pool storage pool = pools[_lpTokens[i]];
      if (pool.lastUpdatedAt > 0) {
        totalWeight = totalWeight.add(_weights[i]).sub(pool.weight);
        pool.weight = _weights[i];
      }
    }
  }

  /// @notice add a new pool for shield mining
  function addPool(address _lpToken, uint256 _weight) public override onlyOwner {
    Pool memory pool = pools[_lpToken];
    require(pool.lastUpdatedAt == 0, "Blacksmith: pool exists");
    pools[_lpToken] = Pool({
      weight: _weight,
      accRewardsPerToken: 0,
      lastUpdatedAt: block.timestamp
    });
    totalWeight = totalWeight.add(_weight);
    poolList.push(_lpToken);
  }

  /// @notice add new pools for shield mining
  function addPools(address[] calldata _lpTokens, uint256[] calldata _weights) external override onlyOwner {
    require(_lpTokens.length == _weights.length, "Blacksmith: size don't match");
    for (uint256 i = 0; i < _lpTokens.length; i++) {
     addPool(_lpTokens[i], _weights[i]);
    }
  }

  /// @notice only statusCode 1 will enable the bonusToken to allow partners to set their program
  function updateBonusTokenStatus(address _bonusToken, uint8 _status) external override onlyOwner {
    require(_status != 0, "Blacksmith: status cannot be 0");
    require(pools[_bonusToken].lastUpdatedAt == 0, "Blacksmith: lpToken is not allowed");
    allowBonusTokens[_bonusToken] = _status;
  }

  /// @notice always assign the same startTime and endTime for both CLAIM and NOCLAIM pool, one bonusToken can be used for only one set of CLAIM and NOCLAIM pools
  function addBonusToken(
    address _lpToken,
    address _bonusToken,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _totalBonus
  ) external override {
    IERC20 bonusToken = IERC20(_bonusToken);
    require(pools[_lpToken].lastUpdatedAt != 0, "Blacksmith: pool does NOT exist");
    require(allowBonusTokens[_bonusToken] == 1, "Blacksmith: bonusToken not allowed");

    BonusToken memory currentBonusToken = bonusTokens[_lpToken];
    if (currentBonusToken.totalBonus != 0) {
      require(currentBonusToken.endTime.add(WEEK) < block.timestamp, "Blacksmith: last bonus period hasn't ended");
      require(IERC20(currentBonusToken.addr).balanceOf(address(this)) == 0, "Blacksmith: last bonus not all claimed");
    }

    require(_startTime >= block.timestamp && _endTime > _startTime, "Blacksmith: messed up timeline");
    require(_totalBonus > 0 && bonusToken.balanceOf(msg.sender) >= _totalBonus, "Blacksmith: incorrect total rewards");

    uint256 balanceBefore = bonusToken.balanceOf(address(this));
    bonusToken.safeTransferFrom(msg.sender, address(this), _totalBonus);
    uint256 balanceAfter = bonusToken.balanceOf(address(this));
    require(balanceAfter > balanceBefore, "Blacksmith: incorrect total rewards");

    bonusTokens[_lpToken] = BonusToken({
      addr: _bonusToken,
      startTime: _startTime,
      endTime: _endTime,
      totalBonus: balanceAfter.sub(balanceBefore),
      accBonusPerToken: 0,
      lastUpdatedAt: _startTime
    });
  }

  /// @notice collect dust to treasury
  function collectDust(address _token) external override {
    Pool memory pool = pools[_token];
    require(pool.lastUpdatedAt == 0, "Blacksmith: lpToken, not allowed");
    require(allowBonusTokens[_token] == 0, "Blacksmith: bonusToken, not allowed");

    IERC20 token = IERC20(_token);
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "Blacksmith: 0 to collect");

    if (_token == address(0)) { // token address(0) == ETH
      payable(treasury).transfer(amount);
    } else {
      token.safeTransfer(treasury, amount);
    }
  }

  /// @notice collect bonus token dust to treasury
  function collectBonusDust(address _lpToken) external override {
    BonusToken memory bonusToken = bonusTokens[_lpToken];
    require(bonusToken.endTime.add(WEEK) < block.timestamp, "Blacksmith: bonusToken, not ready");

    IERC20 token = IERC20(bonusToken.addr);
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "Blacksmith: 0 to collect");
    token.safeTransfer(treasury, amount);
  }

  /// @notice update all pools before update weekly total, otherwise, there will a small (more so for pools with less user interactions) rewards mess up for each pool
  function updateWeeklyTotal(uint256 _weeklyTotal) external override onlyGovernance {
    weeklyTotal = _weeklyTotal;
  }

  /// @notice use start and end to avoid gas limit in one call
  function updatePools(uint256 _start, uint256 _end) external override {
    address[] memory poolListCopy = poolList;
    for (uint256 i = _start; i < _end; i++) {
      updatePool(poolListCopy[i]);
    }
  }

  /// @notice transfer minting rights to new blacksmith
  function transferMintingRights(address _newAddress) external override onlyGovernance {
    cover.setBlacksmith(_newAddress);
  }

  function _calculateCoverRewardsForPeriod(Pool memory _pool) internal view returns (uint256) {
    uint256 timePassed = block.timestamp.sub(_pool.lastUpdatedAt);
    return weeklyTotal.mul(CAL_MULTIPLIER).mul(timePassed).mul(_pool.weight).div(totalWeight).div(WEEK);
  }

  function _calculateBonusForPeriod(BonusToken memory _bonusToken) internal view returns (uint256) {
    if (_bonusToken.endTime == _bonusToken.lastUpdatedAt) return 0;

    uint256 calTime = block.timestamp > _bonusToken.endTime ? _bonusToken.endTime : block.timestamp;
    uint256 timePassed = calTime.sub(_bonusToken.lastUpdatedAt);
    uint256 totalDuration = _bonusToken.endTime.sub(_bonusToken.startTime);
    return _bonusToken.totalBonus.mul(CAL_MULTIPLIER).mul(timePassed).div(totalDuration);
  }

  /// @notice tranfer upto what the contract has
  function _safeTransfer(address _token, uint256 _amount) private nonReentrant {
    IERC20 token = IERC20(_token);
    uint256 balance = token.balanceOf(address(this));
    if (balance > _amount) {
      token.safeTransfer(msg.sender, _amount);
    } else if (balance > 0) {
      token.safeTransfer(msg.sender, balance);
    }
  }

  function _claimCoverRewards(Pool memory pool, Miner memory miner) private nonReentrant {
    if (miner.amount > 0) {
      uint256 minedSinceLastUpdate = miner.amount.mul(pool.accRewardsPerToken).div(CAL_MULTIPLIER).sub(miner.rewardWriteoff);
      if (minedSinceLastUpdate > 0) {
        cover.mint(msg.sender, minedSinceLastUpdate); // mint COVER tokens to miner
      }
    }
  }

  function _claimBonus(BonusToken memory bonusToken, Miner memory miner) private {
    if (bonusToken.totalBonus > 0 && miner.amount > 0 && bonusToken.startTime < block.timestamp) {
      uint256 bonusSinceLastUpdate = miner.amount.mul(bonusToken.accBonusPerToken).div(CAL_MULTIPLIER).sub(miner.bonusWriteoff);
      if (bonusSinceLastUpdate > 0) {
        _safeTransfer(bonusToken.addr, bonusSinceLastUpdate); // transfer bonus tokens to miner
      }
    }
  }
}