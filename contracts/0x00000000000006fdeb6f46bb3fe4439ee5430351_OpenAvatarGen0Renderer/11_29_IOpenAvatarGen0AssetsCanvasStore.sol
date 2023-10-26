// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

struct CanvasHeader {
  uint8 id;
  uint8 width;
  uint8 height;
}

/**
 * @title IOpenAvatarGen0AssetsCanvasStoreRead
 * @dev This interface reads canvas headers.
 */
interface IOpenAvatarGen0AssetsCanvasStoreRead {
  function hasCanvas(uint8 id) external view returns (bool);

  function getCanvasHeader(uint8 id) external view returns (CanvasHeader memory);

  function getNumCanvasIds() external view returns (uint);

  function getCanvasIds() external view returns (uint8[] memory);

  function getCanvasHeight(uint8 id) external view returns (uint8);

  function getCanvasWidth(uint8 id) external view returns (uint8);

  function getCanvasNumBytes(uint8 id) external view returns (uint);

  function getCanvasNumPixels(uint8 id) external view returns (uint);
}

/**
 * @title IOpenAvatarGen0AssetsCanvasStoreWrite
 * @dev This interface writes canvas headers
 */
interface IOpenAvatarGen0AssetsCanvasStoreWrite {
  function addCanvas(CanvasHeader calldata header) external;
}

/**
 * @title IOpenAvatarGen0AssetsCanvasStore
 * @dev This interface reads and writes canvas headers
 */
interface IOpenAvatarGen0AssetsCanvasStore is
  IOpenAvatarGen0AssetsCanvasStoreRead,
  IOpenAvatarGen0AssetsCanvasStoreWrite
{

}