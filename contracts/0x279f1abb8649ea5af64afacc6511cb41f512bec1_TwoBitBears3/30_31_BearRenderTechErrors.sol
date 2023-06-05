// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When the renderers are already configured
error AlreadyConfigured();

/// @dev When Reveal is false
error NotYetRevealed();

/// @dev Only the Renderer can make these calls
error OnlyRenderer();