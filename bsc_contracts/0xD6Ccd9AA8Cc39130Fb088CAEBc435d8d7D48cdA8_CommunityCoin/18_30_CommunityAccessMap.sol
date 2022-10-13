// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

// using like an interface for external call to public mapping in community
abstract contract CommunityAccessMap {
    //receiver => sender
    mapping(address => address) public invitedBy;
}