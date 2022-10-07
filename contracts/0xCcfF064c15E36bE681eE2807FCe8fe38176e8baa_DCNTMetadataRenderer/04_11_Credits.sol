// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============
import {IOnChainMetadata} from "../interfaces/IOnChainMetadata.sol";
import {MetadataRenderAdminCheck} from "./MetadataRenderAdminCheck.sol";

contract Credits is MetadataRenderAdminCheck, IOnChainMetadata {
  /// @notice Array of credits
  mapping(address => Credit[]) internal credits;

  /// @notice Admin function to update description
  /// @param target target description
  /// @param _credits credits for the track
  function updateCredits(address target, Credit[] calldata _credits)
    public
    requireSenderAdmin(target)
  {
    delete credits[target];

    for (uint256 i = 0; i < _credits.length; i++) {
      credits[target].push(
        Credit(_credits[i].name, _credits[i].collaboratorType)
      );
    }

    emit CreditsUpdated({
      target: target,
      sender: msg.sender,
      credits: _credits
    });
  }
}