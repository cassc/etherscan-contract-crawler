/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// SPDX-License-Identifier: LYAA

pragma solidity ^0.8.16;

contract powForkSafeSend {

    function sendETHonPOW(address payable _recipient) public payable {
        require(block.difficulty < 2 ** 64, "POWFORK: this contract only works on pow forks");            
        _recipient.transfer(msg.value);
    }
}