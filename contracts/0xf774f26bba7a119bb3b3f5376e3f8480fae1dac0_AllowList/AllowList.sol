/**
 *Submitted for verification at Etherscan.io on 2022-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract AllowList
 {
    address immutable owner;
    mapping(address => uint256) public balanceOf;

    constructor(address[] memory list) {
        owner = msg.sender;
        _add(list);
    }

    function add(address[] memory newUser) external {
        require(msg.sender == owner, "onlyOwner!!");
        _add(newUser);
    }
    
    function _add(address[] memory newUser) internal {
        for (uint i = 0; i < newUser.length; i++) {
            balanceOf[newUser[i]] = 1;
        }
    }
}