pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT

import "OperaToken.sol";

contract OperaStaking {
    address public owner;
    address public operaToken;
    bool public lockEnabled = true;

    mapping(address => uint256) public stakedAmountForAddress;
    mapping(address => uint256) public stakedTimerForAddress;

    event stakedTokensMoved(
        address user,
        uint256 amount,
        uint256 blocktime,
        bool beingStaked
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function changeLockEnabled(bool locked) external onlyOwner {
        lockEnabled = locked;
    }

    function setOperaToken(address token) external onlyOwner {
        operaToken = token;
    }

    function stakeTokens(uint256 amount) external {
        OperaToken opera = OperaToken(payable(operaToken));
        uint256 balanceBefore = opera.balanceOf(address(this));
        opera.transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = opera.balanceOf(address(this));
        require(
            balanceAfter - amount == balanceBefore,
            "Failed to transfer amount of tokens when moving."
        );
        stakedAmountForAddress[msg.sender] += amount;
        stakedTimerForAddress[msg.sender] = block.timestamp + 2629800;
        emit stakedTokensMoved(
            msg.sender,
            stakedAmountForAddress[msg.sender],
            block.timestamp,
            true
        );
    }

    function getStakedAmount(address user) public view returns (uint256) {
        if (stakedTimerForAddress[user] > block.timestamp) {
            return stakedAmountForAddress[user];
        } else {
            return 0;
        }
    }

    function withdrawStaked() external {
        if (lockEnabled) {
            require(
                stakedTimerForAddress[msg.sender] <= block.timestamp,
                "Still locked"
            );
        }

        uint256 usersAmount = stakedAmountForAddress[msg.sender];
        require(usersAmount > 0, "You have no tokens Staked.");
        stakedAmountForAddress[msg.sender] = 0;
        OperaToken opera = OperaToken(payable(operaToken));
        opera.transfer(msg.sender, usersAmount);
        emit stakedTokensMoved(msg.sender, usersAmount, block.timestamp, false);
    }

    function withdrawStakedWithFee() external {
        uint256 usersAmount = stakedAmountForAddress[msg.sender];
        require(usersAmount > 0, "You have no tokens Staked.");
        stakedTimerForAddress[msg.sender] = 0;
        stakedAmountForAddress[msg.sender] = 0;
        OperaToken opera = OperaToken(payable(operaToken));
        uint256 fee = (usersAmount * 15) / 100;
        emit stakedTokensMoved(msg.sender, usersAmount, block.timestamp, false);
        opera.transfer(msg.sender, usersAmount - fee);
        opera.transfer(owner, fee);
    }
}