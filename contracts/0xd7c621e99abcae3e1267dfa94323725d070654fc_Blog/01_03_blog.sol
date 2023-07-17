// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// This is the simplest thing we can do for representing a blog on IPFS
// Implies that the blog has accessible metadata external to this contract, pointed to by a CID
// Metadata is a JSON file which describes and points to the blog content

import '@openzeppelin/contracts/access/Ownable.sol';

/// @title Blog Contract
/// @author Alex Miller
/// @notice This contract is a simple pointer to a metadata file on IPFS
/// @dev This contract is not tested or audited. Do not use for production.

contract Blog is Ownable {
  // The blog pints to a CID. This is a private variable th
  string public cid;

  // Events
  event updatedCID(string cid);

  // Get the CID of the blog
  function getCID() public view returns (string memory) {
    return cid;
  }

  // Set the CID of the blog - restricted to owner
  function updateCID(string memory _cid) public onlyOwner {
    cid = _cid;
    emit updatedCID(cid);
  }
}