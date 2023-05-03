// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract XimbiaLockV2 {
    uint public constant ximbiaLockDuration = 365 days;
    uint public unlockDate;

    mapping(address => mapping(address => uint)) public tokenUserAmount;

    constructor() {
        unlockDate = block.timestamp + ximbiaLockDuration;
    }

    function deposit(address token, uint amount) external {
        require(amount > 0, "Amount must be greater than 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        tokenUserAmount[token][msg.sender] += amount;
    }

    function withdraw(address token) external {
        require(tokenUserAmount[token][msg.sender] > 0, "No deposit");
        require(block.timestamp > unlockDate, "Lock duration not passed");
        uint amount = tokenUserAmount[token][msg.sender];
        delete tokenUserAmount[token][msg.sender];
        IERC20(token).transfer(msg.sender, amount);
    }
}