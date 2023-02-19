/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

pragma solidity ^0.4.0;

contract MultiTransfer {
    function sendBatch(address[] memory addrs,uint256[] memory amounts) public payable {
        for(uint i = 0; i < addrs.length; i++) {
            addrs[i].transfer(amounts[i]);
        }
    }
}