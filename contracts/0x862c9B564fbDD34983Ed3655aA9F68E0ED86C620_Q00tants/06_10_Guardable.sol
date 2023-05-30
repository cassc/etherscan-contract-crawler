// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IGuardable.sol";

/**
* Abstract contract to be used with ERC1155 or ERC721 or their extensions.
* See ERC721Guardable or ERC1155Guardable for examples of how to overwrite
* setApprovalForAll and approve to be Guardable. Overwriting other functions
* is possible but not recommended.
*/
abstract contract Guardable is IGuardable {
  mapping(address => address) internal locks;

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IGuardable).interfaceId;
  }

  function setGuardian(address guardian) public {
    if (msg.sender == guardian || guardian == address(0)) {
      revert InvalidGuardian();
    }

    locks[msg.sender] = guardian;
    emit GuardianAdded(msg.sender, guardian);
  }

  function guardianOf(address tokenOwner) public view returns (address) {
    return locks[tokenOwner];
  }

  function removeGuardianOf(address tokenOwner) external {
    if (msg.sender != guardianOf(tokenOwner)) {
      revert CallerGuardianMismatch(msg.sender, guardianOf(tokenOwner));
    }
    delete locks[tokenOwner];
    emit GuardianRemoved(tokenOwner);
  }

  function _lockToSelf() internal virtual {
    locks[msg.sender] = msg.sender;
    emit GuardianAdded(msg.sender, msg.sender);
  }
}