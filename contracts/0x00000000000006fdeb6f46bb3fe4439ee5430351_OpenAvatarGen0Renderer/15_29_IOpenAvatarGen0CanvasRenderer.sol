// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

interface IOpenAvatarGen0CanvasRenderer {
  function drawOpenAvatar(uint8 canvasId, bytes32 dna) external view returns (bytes memory);

  function drawOpenAvatarOverlay(bytes memory image, uint8 canvasId, bytes32 dna) external view returns (bytes memory);
}