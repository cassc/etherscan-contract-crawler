/**
 *Submitted for verification at Etherscan.io on 2023-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

   contract testSelfdestruct {
    address payable owner = payable(msg.sender);
    receive() external payable{}
    function killContract() external {
        require(msg.sender == owner);
       
        selfdestruct(owner);
    }}