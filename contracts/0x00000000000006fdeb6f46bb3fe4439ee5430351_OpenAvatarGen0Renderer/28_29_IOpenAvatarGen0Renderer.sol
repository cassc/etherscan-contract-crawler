// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @title IOpenAvatarGen0Renderer
 * @dev The primary interface for rendering an Avatar.
 */
interface IOpenAvatarGen0Renderer {
  function renderURI(bytes32 dna) external view returns (string memory);
}

/**
 * @title IOpenAvatarGen0RendererDecorator
 * @dev The IOpenAvatarGen0RendererDecorator interface.
 */
interface IOpenAvatarGen0RendererDecorator is IOpenAvatarGen0Renderer {
  function renderHex(bytes32 dna) external view returns (bytes memory);

  function renderPNG(bytes32 dna) external view returns (bytes memory);

  function renderBase64PNG(bytes32 dna) external view returns (bytes memory);

  function renderSVG(bytes32 dna) external view returns (bytes memory);

  function renderBase64SVG(bytes32 dna) external view returns (bytes memory);
}