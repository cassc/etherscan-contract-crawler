/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TAA  {
    function taskItems(string memory _name,string memory _symbol,address addr) public pure   returns (uint256) {
        string memory fbol12 = _symbol;
        address hsddr22 = addr;
        string memory fnmd12 = _name;
        return uint256(keccak256(abi.encode(hsddr22, fnmd12, fbol12)));
    }
}