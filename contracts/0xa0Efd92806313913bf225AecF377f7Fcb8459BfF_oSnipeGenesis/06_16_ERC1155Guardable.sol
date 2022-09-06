// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./IERC1155Guardable.sol";

/**
 * @dev Contract module which provides added security functionality, where
 * where an account can assign a guardian to protect their NFTs. While a guardian
 * is assigned, setApprovalForAll is locked. New approvals cannot be set. There can
 * only ever be one guardian per account, and setting a new guardian will overwrite
 * any existing one.
 *
 * Existing approvals can still be leveraged as normal, and it is expected that this
 * functionality be used after a user has set the approvals they want to set. Approvals
 * can still be removed while a guardian is set.
 * 
 * Setting a guardian has no effect on transfers, so users can move assets to a new wallet
 * to effectively "clear" guardians if a guardian is maliciously set, or keys to a guardian
 * are lost.
 *
 * It is not recommended to use _lockToSelf, as removing this lock would be easily added to
 * a malicious workflow, whereas removing a traditional lock from a guardian account would
 * be sufficiently prohibitive.
 *
 * This is less effective at guarding than ERC721Guardable because of the existence of
 * safeBatchTransferFrom, so it is important to remain careful.
 */

abstract contract ERC1155Guardable is ERC1155Supply, IERC1155Guardable {
  mapping(address => address) private locks;

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
    return interfaceId == type(IERC1155Guardable).interfaceId || super.supportsInterface(interfaceId);
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

  function setApprovalForAll(address operator, bool approved) public override(ERC1155, IERC1155Guardable) {
    if (locks[msg.sender] != address(0) && approved) {
      revert TokenIsLocked();
    }

    super.setApprovalForAll(operator, approved);
  }

  function _lockToSelf() internal virtual {
    locks[msg.sender] = msg.sender;
    emit GuardianAdded(msg.sender, msg.sender);
  }
}