/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

pragma solidity ^0.7.0;
// SPDX-License-Identifier: Unlicensed
pragma abicoder v2;
contract zombier {

    uint public p;
    receive()external payable {}
    fallback()external payable {}

    mapping(address => bool)public Operater;

    function SetOperater(address _receiveaddress,bool isTrue)external{
        Operater[_receiveaddress] = isTrue;
    } 

    function test()external{
        require(Operater[msg.sender],"invalid");
        p += 1;
    }    
}