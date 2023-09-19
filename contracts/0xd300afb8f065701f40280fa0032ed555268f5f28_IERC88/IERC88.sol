/**
 *Submitted for verification at Etherscan.io on 2023-08-02
*/

/**
 *Submitted for verification at BscScan.com on 2023-07-16
*/

// SPDX-License-Identifier: evmVersion, MIT

pragma solidity ^0.6.12;

contract IERC88 {

    
    

    address[] public cAddr;

    function addContract(address c) external {
        cAddr.push(c);
    }

    function getContractCount() external view returns (uint256) {
        return cAddr.length;
    }

    function getContractAtIndex(uint256 index) external view returns (address) {
        require(index < cAddr.length, "Index out of range");
        return cAddr[index];
    }
}