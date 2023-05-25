// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

// The Window is time-based so will rely on time, however period > 30 minutes
// minimise the risk of oracle manipulation.
// solhint-disable not-rely-on-time

/**
 * @title A windowed contract
 * @notice Provides a window for actions to occur
 */
contract Windowed {
  /* ========== STATE VARIABLES ========== */

  /**
   * @notice The timestamp of the window start
   */
  uint256 public startWindow;

  /**
   * @notice The timestamp of the window end
   */
  uint256 public endWindow;

  /* ========== CONSTRUCTOR ========== */

  constructor(uint256 _startWindow, uint256 _endWindow) {
    require(_startWindow > block.timestamp, "Windowed/StartInThePast");
    require(_endWindow > _startWindow + 1 days, "Windowed/MustHaveDuration");

    startWindow = _startWindow;
    endWindow = _endWindow;
  }

  /* ========== MODIFIERS ========== */

  modifier inWindow() {
    require(block.timestamp >= startWindow, "Windowed/HasNotStarted");
    require(block.timestamp <= endWindow, "Windowed/HasEnded");
    _;
  }

  modifier afterWindow() {
    require(block.timestamp > endWindow, "Windowed/NotEnded");
    _;
  }
}