// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// The IProxyBotSpecialEditionInspector class is used to validate special edition tokens.
// It's a separate contract so that it can be upgraded without having to upgrade the ProxyBot contract.
interface IProxyBotSpecialEditionInspector {
  
  // Check the given address to see if whatever our logic is for validating special edition tokens determines to be valid.
  // Returns a tuple containing a boolean and a string.
  // The boolean is true if the address is valid, false if not.
  // The string is the indentifier of the special edition, whatever that turns out to be.
  function validateSpecialEdition(address _ownerAddress, address _contractToCheck, bool checkSpecificTokenId, uint256 tokenId) external view returns (bool, string memory);
}