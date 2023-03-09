// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "../Guardable.sol";

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

contract ERC721Guardable is ERC721, Guardable {
  string internal baseUri;

  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  function supportsInterface(bytes4 interfaceId) public view virtual override(Guardable, ERC721) returns (bool) {
    return Guardable.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
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

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseUri, _toString(id)));
  }

  // From ERC721A
  /**
    * @dev Converts a uint256 to its ASCII string decimal representation.
  */
  function _toString(uint256 value) internal pure virtual returns (string memory str) {
      assembly {
          // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
          // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
          // We will need 1 word for the trailing zeros padding, 1 word for the length,
          // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
          let m := add(mload(0x40), 0xa0)
          // Update the free memory pointer to allocate.
          mstore(0x40, m)
          // Assign the `str` to the end.
          str := sub(m, 0x20)
          // Zeroize the slot after the string.
          mstore(str, 0)

          // Cache the end of the memory to calculate the length later.
          let end := str

          // We write the string from rightmost digit to leftmost digit.
          // The following is essentially a do-while loop that also handles the zero case.
          // prettier-ignore
          for { let temp := value } 1 {} {
              str := sub(str, 1)
              // Write the character to the pointer.
              // The ASCII index of the '0' character is 48.
              mstore8(str, add(48, mod(temp, 10)))
              // Keep dividing `temp` until zero.
              temp := div(temp, 10)
              // prettier-ignore
              if iszero(temp) { break }
          }

          let length := sub(end, str)
          // Move the pointer 32 bytes leftwards to make room for the length.
          str := sub(str, 0x20)
          // Store the length.
          mstore(str, length)
      }
  }
}