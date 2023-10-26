// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @title OpenAvatarGen0AssetsCanvasIdStore
 * @dev This contracts stores a canvas ID.
 */
abstract contract OpenAvatarGen0AssetsCanvasIdStore {
  /// @notice The canvas ID.
  uint8 public canvasId;

  constructor(uint8 canvasId_) {
    canvasId = canvasId_;
  }

  /**
   * @notice Get the canvas ID.
   * @return The canvas ID.
   */
  function getCanvasId() external view returns (uint8) {
    return canvasId;
  }
}