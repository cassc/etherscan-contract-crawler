/**
 *Submitted for verification at Etherscan.io on 2023-05-12
*/

pragma solidity ^0.8.0;

contract BaseFee {
    function getCurrentBaseFee() public view returns (uint256) {
        return block.basefee;
    }
}