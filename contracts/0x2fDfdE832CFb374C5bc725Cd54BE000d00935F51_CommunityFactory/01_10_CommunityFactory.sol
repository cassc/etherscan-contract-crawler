// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import './Community.sol';

contract CommunityFactory {
  mapping(address => Community) public communityMappings;

  function createCommunity() public {
    // Whoever creates the comminity using our CommunityFactory is the owner
    Community community = new Community(msg.sender);

    communityMappings[msg.sender] = community;
  }

  function getDeployedCommunity(address ownerAddress) public view returns (Community) {
    return communityMappings[ownerAddress];
  }
}