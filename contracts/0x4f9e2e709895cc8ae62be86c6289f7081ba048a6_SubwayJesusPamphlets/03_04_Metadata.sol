// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Dependencies.sol";

contract Metadata {
  using Strings for uint256;

  function tokenURI(uint256 tokenId) external pure returns (string memory) {
    return string(abi.encodePacked('ipfs://bafybeib5wqab3uj7zcoajmmykwqiglqgdkb5dnuc2fecdaxx6tkwfhlrse/', tokenId.toString(), '.json'));
  }
}
