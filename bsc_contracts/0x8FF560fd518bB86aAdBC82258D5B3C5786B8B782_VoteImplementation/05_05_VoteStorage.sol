// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract VoteStorage is Admin {

    address public implementation;

    string public topic;

    uint256 public numOptions;

    uint256 public deadline;

    // voters may contain duplicated address, if one submits more than one votes
    address[] public voters;

    // voter address => vote
    // vote starts from 1, 0 is reserved for no vote
    mapping (address => uint256) public votes;

}