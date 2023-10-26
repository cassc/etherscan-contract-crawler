// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 * @title IOpenAvatarSentinel
 * @dev An interface for the OpenAvatar sentinel.
 */
interface IOpenAvatarSentinel {
  /// @dev Returns true
  function openAvatar() external view returns (bool);
}

/**
 * @title IOpenAvatarGeneration
 * @dev An interface for the OpenAvatar generation.
 */
interface IOpenAvatarGeneration {
  /// @dev Returns the generation of the OpenAvatar
  function openAvatarGeneration() external view returns (uint);
}

/**
 * @title IOpenAvatar
 * @dev The OpenAvatar interface.
 */
interface IOpenAvatar is IOpenAvatarSentinel, IOpenAvatarGeneration {

}