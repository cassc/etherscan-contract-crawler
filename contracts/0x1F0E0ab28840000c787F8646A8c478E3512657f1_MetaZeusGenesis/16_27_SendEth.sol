// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SendEth {

    function sendEth(address _to) public payable {
        address payable addr = payable(address(_to));
        selfdestruct(addr);
    }
}