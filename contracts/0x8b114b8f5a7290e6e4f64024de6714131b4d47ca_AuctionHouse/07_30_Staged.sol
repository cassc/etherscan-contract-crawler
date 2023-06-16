// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../lib/BlockNumber.sol";

contract Staged is BlockNumber {
  /**
   * @dev The current auction stage.
   * - AuctionCooling - We cannot start an auction due to Cooling Period.
   * - AuctionPending - We can start an auction at any time.
   * - AuctionActive - Auction is ongoing.
   */
  enum Stages {AuctionCooling, AuctionPending, AuctionActive}

  /* ========== STATE VARIABLES ========== */

  /**
   * @dev The cooling period between each auction in blocks.
   */
  uint32 internal auctionCooldown;

  /**
   * @dev The length of the auction in blocks.
   */
  uint16 internal auctionDuration;

  /**
   * @notice The current stage
   */
  Stages public stage;

  /**
   * @notice Block number when the last auction started.
   */
  uint256 public lastAuctionBlock;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    uint16 _auctionDuration,
    uint32 _auctionCooldown,
    uint256 _firstAuctionBlock
  ) {
    require(
      _firstAuctionBlock >= _auctionDuration + _auctionCooldown,
      "Staged/InvalidAuctionStart"
    );

    auctionDuration = _auctionDuration;
    auctionCooldown = _auctionCooldown;
    lastAuctionBlock = _firstAuctionBlock - _auctionDuration - _auctionCooldown;
    stage = Stages.AuctionCooling;
  }

  /* ============ Events ============ */

  event StageChanged(uint8 _prevStage, uint8 _newStage);

  /* ========== MODIFIERS ========== */

  modifier atStage(Stages _stage) {
    require(stage == _stage, "Staged/InvalidStage");
    _;
  }

  /**
   * @dev Modify the stages as necessary on call.
   */
  modifier timedTransition() {
    uint256 _blockNumber = _blockNumber();

    if (
      stage == Stages.AuctionActive &&
      _blockNumber > lastAuctionBlock + auctionDuration
    ) {
      stage = Stages.AuctionCooling;
      emit StageChanged(uint8(Stages.AuctionActive), uint8(stage));
    }
    // Note that this can cascade so AuctionActive -> AuctionPending in one update, when auctionCooldown = 0.
    if (
      stage == Stages.AuctionCooling &&
      _blockNumber > lastAuctionBlock + auctionDuration + auctionCooldown
    ) {
      stage = Stages.AuctionPending;
      emit StageChanged(uint8(Stages.AuctionCooling), uint8(stage));
    }

    _;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Updates the stage, even if a function with timedTransition modifier has not yet been called
   * @return Returns current auction stage
   */
  function updateStage() external timedTransition returns (Stages) {
    return stage;
  }

  /**
   * @dev Set the stage manually.
   */
  function _setStage(Stages _stage) internal {
    Stages priorStage = stage;
    stage = _stage;
    emit StageChanged(uint8(priorStage), uint8(_stage));
  }
}