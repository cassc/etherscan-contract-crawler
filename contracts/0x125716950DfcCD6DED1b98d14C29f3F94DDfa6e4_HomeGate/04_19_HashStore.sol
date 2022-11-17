//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HashStore is Ownable {
  mapping(bytes32 => bool) public hashes;

  function addHash(bytes32 key) external onlyOwner {
    require(!hashes[key], "cannot add a hash again");

    hashes[key] = true;
  }
}