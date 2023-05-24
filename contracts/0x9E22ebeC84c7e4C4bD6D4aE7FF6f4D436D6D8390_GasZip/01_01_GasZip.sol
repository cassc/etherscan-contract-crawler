// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract GasZip {

    event Deposit(address from, uint256 chains, uint256 amount, address to);

    
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function deposit(uint256 chains, address to) payable external {
        require(msg.value != 0);
        emit Deposit(msg.sender, chains, msg.value, to);
    }

    function withdraw(address token) external {
        require(msg.sender == owner);
        if (token == address(0)) {
            owner.call{value: address(this).balance}("");
        } else {
            IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
        }
    }

    function newOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}