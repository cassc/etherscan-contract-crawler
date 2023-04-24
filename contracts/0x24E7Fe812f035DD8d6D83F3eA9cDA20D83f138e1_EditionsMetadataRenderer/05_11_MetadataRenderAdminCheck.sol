// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {IHolographDropERC721} from "../interface/IHolographDropERC721.sol";

contract MetadataRenderAdminCheck {
  error Access_OnlyAdmin();

  /// @notice Modifier to require the sender to be an admin
  /// @param target address that the user wants to modify
  modifier requireSenderAdmin(address target) {
    if (target != msg.sender && !IHolographDropERC721(target).isAdmin(msg.sender)) {
      revert Access_OnlyAdmin();
    }

    _;
  }
}