// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Guardable.sol";

/**
 * @dev Contract module which provides added security functionality, where
 * where an account can assign a guardian to protect their NFTs. While a guardian
 * is assigned, setApprovalForAll and approve are both locked. New approvals cannot be set. There can
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
 */

contract ERC721AGuardable is ERC721A, Guardable {

  constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

  function supportsInterface(bytes4 interfaceId) public view virtual override(Guardable, ERC721A) returns (bool) {
    return Guardable.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
  }

  function approve(address to, uint256 tokenId) public override {
    if (locks[msg.sender] != address(0)) {
      revert TokenIsLocked();
    }

    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override {
    if (locks[msg.sender] != address(0) && approved) {
      revert TokenIsLocked();
    }

    super.setApprovalForAll(operator, approved);
  }
}