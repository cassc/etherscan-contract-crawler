/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract TOKEN {

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function release() external {
        selfdestruct(payable(msg.sender));
    } 
    
}