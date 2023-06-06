/**
 *Submitted for verification at Etherscan.io on 2023-05-07
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Lock {
    address private _owner;
    uint256 private _until;
    
    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    
    function lock(IERC20 token, uint256 amount, uint256 until) public onlyOwner {
        token.transferFrom(_owner, address(this), amount);
        _until = until;
    }
    
    function unlock(IERC20 token, uint256 amount) public onlyOwner {
        require(block.timestamp > _until);
        token.transfer(_owner, amount);
    }
}