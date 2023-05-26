// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./base/BaseFeeder.sol";
import "./interfaces/IxGF.sol";
import "./interfaces/IStakingPoolManager.sol";
import "./SafeToken.sol";

contract GFFeeder01 is BaseFeeder {
  using SafeToken for address;

  struct Snapshot {
    uint112 stakingPoolTvl;
    uint112 xGFTvl;
    uint32 blockNumber;
  }

  uint256 public constant MAX_BIAS = 10000;

  IStakingPoolManager public stakingPoolManager;
  address public stakingPool;

  uint256 public bias = 3000; // 30%

  /// @dev Mapping ( round off timestamp to week => Snapshot ) to keep track of each week snapshot
  mapping(uint256 => Snapshot) public weeklySnapshotOf;

  event MissingSnapshot(uint40 fromBlock, uint40 toBlock);
  event SetBias(uint256 oldBias, uint256 newBias);


  constructor(
    address _stakingPool,
    address _stakingPoolManager,
    address _rewardManager,
    address _rewardSource,
    uint256 _rewardRatePerBlock,
    uint40 _lastRewardBlock,
    uint40 _rewardEndBlock
  ) BaseFeeder(_rewardManager, _rewardSource, _rewardRatePerBlock, _lastRewardBlock, _rewardEndBlock) {
    stakingPoolManager = IStakingPoolManager(_stakingPoolManager);
    stakingPool = _stakingPool;

    require(stakingPoolManager.reward() == rewardManager.rewardToken(), "invalid legacy reward");

    token.safeApprove(_rewardManager, type(uint256).max);
  }

  function stakingPoolTvl() public view returns (uint256) {
    return IERC20(token).balanceOf(stakingPool);
  }

  function xGFTvl() public view returns (uint256) {
    return IxGF(rewardManager.xGF()).supply() + rewardManager.lastTokenBalance();
  }

  function getRate(uint256 timestamp) external view returns (uint256, uint256) {
    uint256 _weekCursor = _timestampToFloorWeek(timestamp);
    return _getRate(weeklySnapshotOf[_weekCursor], rewardRatePerBlock);
  }

  function _feed() override internal  {
    // 1. Feed reward for this week
    Snapshot memory _thisWeekSnapshot = weeklySnapshotOf[_timestampToFloorWeek(block.timestamp)];

    if (_thisWeekSnapshot.blockNumber == 0) {
      // missing a call to snapshot this week, need to fix with inject reward
      emit MissingSnapshot(lastRewardBlock, uint40(block.number));
    } else {
      _updatePools(_thisWeekSnapshot, lastRewardBlock);
    }
    _updateLastRewardBlock(uint40(block.number));
    // 3. Record Snapshot to be used for next week
    _takeSnapshot(_timestampToFloorWeek(block.timestamp + WEEK - 1));
  }

  function _updateLastRewardBlock(uint40 blockNumber) internal {
    uint40 _rewardEndBlock = rewardEndBlock;
    lastRewardBlock = blockNumber > _rewardEndBlock ? _rewardEndBlock : blockNumber;
  }

  function _updatePools(Snapshot memory _snapshot, uint40 _lastRewardBlock) internal {
    (uint256 rate1, uint256 rate2) = _getRate(_snapshot, rewardRatePerBlock);
    _setStakingPoolManagerRate(rate1);
    uint256 _feedAmount = _feedRewardManager(rate2, _lastRewardBlock, block.number);
    emit Feed(_feedAmount);
  }


  function _takeSnapshot(uint256 _weekCursor) internal {
    weeklySnapshotOf[_weekCursor] = Snapshot({
      stakingPoolTvl: uint112(stakingPoolTvl()),
      xGFTvl: uint112(xGFTvl()),
      blockNumber: uint32(block.number)
    });
  }

  function _setStakingPoolManagerRate(uint256 _rate) internal {
    if (stakingPoolManager.rewardPerBlock() == _rate) {
      stakingPoolManager.distributeRewards();
    } else {
      stakingPoolManager.setRewardPerBlock(_rate);
    }
  }

  function _feedRewardManager(
    uint256 _rate,
    uint256 _fromBlock,
    uint256 _toBlock
  ) internal returns (uint256) {
    uint256 blockDelta = _getMultiplier(_fromBlock, _toBlock, rewardEndBlock);
    if (blockDelta == 0) {
      return 0;
    }
    uint256 _toDistribute = _rate * blockDelta;
    if (_toDistribute > 0) {
      token.safeTransferFrom(rewardSource, address(this), _toDistribute);
      rewardManager.feed(_toDistribute);
    }

    return _toDistribute;
  }

  function _getMultiplier(
    uint256 _from,
    uint256 _to,
    uint256 _endBlock
  ) internal pure returns (uint256) {
    if ((_from >= _endBlock) || (_from > _to)) {
      return 0;
    }

    if (_to <= _endBlock) {
      return _to - _from;
    }
    return _endBlock - _from;
  }

  function _getRate(Snapshot memory _snapshot, uint256 _maxRatePerBlock)
    internal
    view
    returns (uint256 rate1, uint256 rate2)
  {
    if (_snapshot.stakingPoolTvl == 0 || _snapshot.xGFTvl == 0) {
      rate1 = 0;
      rate2 = 0;
      return (rate1, rate2);
    }

    uint256 _bias = bias;
    uint256 _adjustedV1Weight = uint256(_snapshot.stakingPoolTvl) * (MAX_BIAS - _bias);
    uint256 _adjustedV2Weight = uint256(_snapshot.xGFTvl) * (MAX_BIAS + _bias);
    uint256 _totalWeight = _adjustedV1Weight + _adjustedV2Weight;

    rate1 = (_maxRatePerBlock * _adjustedV1Weight) / _totalWeight;
    rate2 = (_maxRatePerBlock * _adjustedV2Weight) / _totalWeight;
  }

  function _timestampToFloorWeek(uint256 _timestamp) internal pure returns (uint256) {
    return (_timestamp / WEEK) * WEEK;
  }

  function setBias(uint256 _newBias, bool _distribute) external onlyOwner {
    require(_newBias <= MAX_BIAS, "exceed MAX_BIAS");
    if (_distribute) {
      _feed();
    }

    uint256 _oldBias = bias;
    bias = _newBias;
    emit SetBias(_oldBias, _newBias);
  }

  function injectSnapshot(uint256 _timestamp, Snapshot memory _snapshot) external onlyOwner {
    uint256 _weekCursor = _timestampToFloorWeek(_timestamp);
    weeklySnapshotOf[_weekCursor] = _snapshot;
  }

  function setRewardRatePerBlock(uint256 _newRate) override external onlyOwner {
    // 1. feed
    Snapshot memory _thisWeekSnapshot = weeklySnapshotOf[_timestampToFloorWeek(block.timestamp)];
    require(_thisWeekSnapshot.blockNumber != 0, "!thisWeekSnapshot");
    _updatePools(_thisWeekSnapshot, lastRewardBlock);
    _updateLastRewardBlock(uint40(block.number));
    _takeSnapshot(_timestampToFloorWeek(block.timestamp + WEEK - 1));
    
    // 2. update rate
    uint256 _nextWeekCursor = _timestampToFloorWeek(block.timestamp + WEEK - 1);
    _takeSnapshot(_nextWeekCursor);

    uint256 _prevRate = rewardRatePerBlock;
    rewardRatePerBlock = _newRate;

    // 3. apply new rate to staking pool
    (uint newRate1,) = _getRate(_thisWeekSnapshot, _newRate);
    _setStakingPoolManagerRate(newRate1);

    emit SetNewRewardRatePerBlock(msg.sender, _prevRate, _newRate);
  }
}