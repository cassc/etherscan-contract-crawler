// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {IOpenAvatar} from './IOpenAvatar.sol';

/**
 * @title IOpenAvatarGeneration
 * @dev OpenAvatar Generation 0 common definitions.
 */
abstract contract OpenAvatarGenerationZero is IOpenAvatar {
  /// @dev OpenAvatar Generation 0.
  uint public constant OPENAVATAR_GENERATION_ZERO = 0;

  /////////////////////////////////////////////////////////////////////////////
  // IOpenAvatarGeneration
  /////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Returns 0, in reference to Open Avatar Generation 0.
   * @return 0 (zero).
   */
  function openAvatarGeneration() external pure returns (uint) {
    return OPENAVATAR_GENERATION_ZERO;
  }

  /////////////////////////////////////////////////////////////////////////////
  // IOpenAvatarSentinel
  /////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Returns true.
   * @dev This is a sentinel function to indicate that this contract is an
   * OpenAvatar contract.
   * @return True.
   */
  function openAvatar() public pure returns (bool) {
    return true;
  }

  /////////////////////////////////////////////////////////////////////////////
  // ERC-165: Standard Interface Detection
  /////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Checks if the contract supports an interface.
   * @param interfaceId The interface identifier, as specified in ERC-165.
   * @return True if the contract supports interfaceID, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      // IOpenAvatar
      interfaceId == 0xfdf02ac8 || // ERC165 interface ID for IOpenAvatarGeneration.
      interfaceId == 0x7b65147c || // ERC165 interface ID for IOpenAvatarSentinel.
      interfaceId == 0x86953eb4; // ERC165 interface ID for IOpenAvatar.
  }
}