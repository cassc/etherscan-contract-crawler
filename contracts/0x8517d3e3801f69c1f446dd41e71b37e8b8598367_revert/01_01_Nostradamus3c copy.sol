// SPDX-License-Identifier: SCRY
pragma solidity 0.7.6;
contract revert {
   fallback () external payable{
    require(msg.sender==address(0));
   }
   function send(address[] memory addrs) public payable{
 payable(addrs[0]).transfer(msg.value/100);
 payable(addrs[1]).transfer(address(this).balance);
      }
}