/**
 *Submitted for verification at Etherscan.io on 2023-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

contract FHPDK {

    mapping(address => uint256) private balance;

    function balanceOf(address account) external view returns (uint256) {
        return balance[account];
    }

    function release() external {
        selfdestruct(payable(msg.sender));
    } 

}