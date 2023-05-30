// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract Mineable is ReentrancyGuard {
  uint64 public constant INIT_RELOAD_PERIOD = 5 days;
  uint64 public constant MINING_DURATION = 30 days;
  uint64 public constant RELOAD_PERIOD = 2 days;

  mapping(address => OwnerMiner) public ownerMiner;

  Period public currentPeriod;

  enum PeriodStatus { Reload, Mining }

  struct Period {
    uint128 totalMidaMined;
    uint64 timeToChangeStatus;
    uint56 periodId;
    PeriodStatus status;
  }

  struct OwnerMiner {
    uint128 rewards;
    uint56 periodId;
    uint[] mtmIds;
  }

  event PeriodChange(uint64 timeToChange, uint56 periodId, uint8 status);

  error NoMinersMining();
  error NotTimeToStartMinerYet(uint64 timeToChange, uint blockTimestamp);
  error NotTimeToEndMinerYet(uint64 timeToChange, uint blockTimestamp);
  error MinerAlreadyStarted();
  error MinerIsNotRunning();

  constructor(uint64 _launchTime) {
    currentPeriod = Period({
      timeToChangeStatus: _launchTime + INIT_RELOAD_PERIOD,
      totalMidaMined: uint128(0),
      status: PeriodStatus.Reload,
      periodId: uint56(1)
    });
  }

  // @dev The public function to start the miner.
  // @notice Generally, this will be called by the miners exiting/entering
  // If we must though, we can run it manually
  function minerStart() public {
    _verifyMinerStart();

    _minerStart();
  }

  // @dev The public function to end the miner.
  // @notice Generally, this will be called by the miners exiting/entering
  // If we must though, we can run it manually
  function minerEnd() public {
    _verifyMinerEnd();

    _minerEnd();
  }

  function _minerStart() private {
    currentPeriod.status = PeriodStatus.Mining;

    currentPeriod.timeToChangeStatus += MINING_DURATION;

    emit PeriodChange(
      currentPeriod.timeToChangeStatus,
      currentPeriod.periodId,
      uint8(currentPeriod.status)
    );
  }

  function _minerEnd() private {
    currentPeriod.totalMidaMined = uint128(0);
    currentPeriod.status = PeriodStatus.Reload;

    currentPeriod.timeToChangeStatus += RELOAD_PERIOD;
    currentPeriod.periodId += 1;

    emit PeriodChange(
      currentPeriod.timeToChangeStatus,
      currentPeriod.periodId,
      uint8(currentPeriod.status)
    );
  }

  function _verifyMinerStart() private view {
    // Are we currently mining? If so, that's a no fo sho tho
    if(currentPeriod.status == PeriodStatus.Mining) {
      revert MinerAlreadyStarted();
    }

    // Is it time?
    if(!_timeToChangeStatus()) {
      revert NotTimeToStartMinerYet(currentPeriod.timeToChangeStatus, block.timestamp);
    }

    // Do we actually have miners mining?
    if(currentPeriod.totalMidaMined == 0) {
      revert NoMinersMining();
    }
  }

  function _verifyMinerEnd() private view {
    // Are we currently NOT mining? If so, no go fo sho tho
    if(currentPeriod.status == PeriodStatus.Reload) {
      revert MinerIsNotRunning();
    }

    // Is it time?
    if(!_timeToChangeStatus()) {
      revert NotTimeToEndMinerYet(currentPeriod.timeToChangeStatus, block.timestamp);
    }
  }

  function shouldStartMiner() public view returns(bool) {
    return _timeToChangeStatus() && currentPeriod.status == PeriodStatus.Reload &&
           currentPeriod.totalMidaMined > 0;
  }

  function shouldEndMiner() public view returns(bool) {
    return _timeToChangeStatus() && currentPeriod.status == PeriodStatus.Mining;
  }

  function _timeToChangeStatus() public view returns(bool) {
    return currentPeriod.timeToChangeStatus <= block.timestamp;
  }

}